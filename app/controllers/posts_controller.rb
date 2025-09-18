require "open-uri"

class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :generate_description, :generate_ai_image]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:edit, :update, :destroy]

  # --- INDEX & SHOW ---
  def index
    @posts = Post.public_posts.published.order(created_at: :desc).page(params[:page]).per(9)
  end

  def show
    unless @post.public && @post.published? || (current_user && @post.user == current_user)
      redirect_to root_path, alert: "You don't have access to that post."
    end
  end

  # --- NEW & CREATE ---
  def new
    @post = current_user.posts.new
  end

  def create
    @post = current_user.posts.new(post_params)
    @post.published_at ||= Time.current

    @post.description = formatted_description_for_post(@post, params[:keywords], params[:links], post_params[:description])

    if @post.save
      attach_ai_image(@post)

      
      # Schedule sync to WordPress
      schedule_sync(@post)

      redirect_to @post, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # --- EDIT & UPDATE ---
  def edit; end

  def update
    updated_params = post_params.merge(
      description: formatted_description_for_post(@post, params[:keywords], params[:links], post_params[:description])
    )

    if @post.update(updated_params)
      attach_ai_image(@post, replace: true)

      # Schedule sync to WordPress
      schedule_sync(@post)

      redirect_to @post, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # --- DESTROY ---
  def destroy
    @post.destroy
    redirect_to posts_url, notice: "Post was successfully destroyed."
  end

  # --- AI Helpers ---
  def generate_description
    title = params[:title]
    keywords = Array(params[:keywords])
    links = Array(params[:links])

    begin
      description = AiDescriptionGenerator.new(
        title: title,
        image: params[:image],
        keywords: keywords,
        links: links
      ).call

      formatted_description = format_description(title, description, keywords, links)
      render json: { description: formatted_description }
    rescue => e
      Rails.logger.error("AI Description Error: #{e.full_message}")
      render json: { error: "Failed to generate description." }, status: :internal_server_error
    end
  end

  def generate_ai_image
    title = params[:title]

    begin
      url = AiImageService.generate(prompt: title)
      render json: { success: true, image_url: url }
    rescue => e
      Rails.logger.error("AI Image Error: #{e.full_message}")
      render json: { error: "Failed to generate image. Try again." }, status: :unprocessable_entity
    end
  end

  def generate_qa
    title = params[:title].to_s.strip
    keywords = Array(params[:keywords]).map(&:strip).reject(&:blank?)

    qa_array = GenerateQaService.new(title: title, keywords: keywords).call
    render json: { qa: qa_array }
  rescue => e
    Rails.logger.error("Generate QA failed: #{e.full_message}")
    render json: { error: "Failed to generate Q&A" }, status: :internal_server_error
  end

  private

  # --- CALLBACKS & HELPERS ---
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(
      :title,
      :description,
      :image,
      :ai_image_url,
      :public,
      :published_at,
      keywords: [],
      links: [],
      questions: [],
      answers: []
    )
  end

  def authorize_user
    redirect_to posts_path, alert: "Not authorized." unless current_user == @post.user
  end

  
  # --- SCHEDULE WORDPRESS SYNC ---
  def schedule_sync(post)
    if post.published_at > Time.current
      PublishPostJob.set(wait_until: post.published_at).perform_later(post.id)
    else
      SyncToWordpressJob.perform_later(post.id)
    end
  end

  # --- AI IMAGE ATTACHMENT ---
  def attach_ai_image(post, replace: false)
    return unless post.ai_image_url.present?

    post.image.purge if replace && post.image.attached?

    begin
      downloaded_image = URI.open(post.ai_image_url)
      post.image.attach(io: downloaded_image, filename: "ai_image_#{post.id}.png")
      Rails.logger.info "✅ AI image attached for Post ##{post.id}"
    rescue => e
      Rails.logger.error("AI Image attach failed for Post ##{post.id}: #{e.full_message}")
    end
  end

  # --- DESCRIPTION FORMATTING ---
  def formatted_description_for_post(post, keywords = [], links = [], custom_description = nil)
    keywords = Array(keywords)
    links = Array(links)
    description_to_format = custom_description || post.description
    format_description(post.title, description_to_format, keywords, links)
  end

  def format_description(title, description, keywords = [], links = [])
    return " " if description.blank?

    clean_description = description.dup
    clean_description.gsub!(/^(title|introduction):?/i, '') # only remove literal "title:" or "introduction:"
    clean_description.strip!

    # Remove any existing title HTML from the description
    title_pattern = /<h2><strong>.*?<\/strong><\/h2>/i
    clean_description.gsub!(title_pattern, '')

    keywords = Array(keywords)
    links = Array(links)

    # Replace keywords with styled links
    if keywords.present? && links.present? && keywords.size == links.size
      keywords.each_with_index do |kw, i|
        next if kw.blank? || links[i].blank?
        pattern = /(?<!\w)(#{Regexp.escape(kw)})(?!\w)/i
        replacement = "<a href='#{links[i]}' target='_blank' style=\"color:#2563eb; font-weight:600; text-decoration:underline !important;\">\\1</a>"
        clean_description.gsub!(pattern, replacement)
      end
    end

    # Append missing keywords
    missing = keywords.reject { |kw| clean_description.downcase.include?(kw.to_s.downcase) }
    unless missing.empty?
      missing_links = missing.map do |kw|
        idx = keywords.index(kw)
        link = links[idx] if idx
        "<a href='#{link}' target='_blank' style=\"color:#2563eb; font-weight:600; text-decoration:underline !important;\">#{kw}</a>"
      end
      clean_description += "<div class='spacing'></div><p><strong>Related Keywords:</strong> #{missing_links.join(', ')}</p>"
    end

    # Title + Paragraph formatting
    title_html = "<h2><strong>#{title}</strong></h2>"
    paragraphs = clean_description.split(/\n\n+/)
    formatted_paragraphs = paragraphs.map do |para|
      para.strip!
      next if para.empty?

      case para
      when /^##\s+(.+)/
        "<h3>#{$1.strip}</h3>"
      when /^(\d+\.|\-)\s+/
        items = para.split("\n").map { |line| "<li>#{line.gsub(/^(\d+\.|\-)\s+/, '').strip}</li>" }.join
        "<ul>#{items}</ul>"
      else
        "<p>#{para.gsub(/\n/, '<br>')}</p>"
      end
    end.compact

    # Always add the new title at the beginning
    final_content = "#{title_html}<div class='spacing'></div>#{formatted_paragraphs.join('<div class=\"spacing\"></div>')}"
    
    final_content
  end

end
