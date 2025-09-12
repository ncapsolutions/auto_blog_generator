require "open-uri"

class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :generate_description, :generate_ai_image]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:edit, :update, :destroy]

  # --- INDEX & SHOW ---
  def index
    @posts = Post.public_posts.published.order(created_at: :desc)
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

    if @post.save
      attach_ai_image(@post)

      # Schedule sync to WordPress
      # schedule_sync(@post)

      redirect_to @post, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # --- EDIT & UPDATE ---
  def edit; end

  def update
    if @post.update(post_params)
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
    image = params[:image]

    begin
      description = AiDescriptionGenerator.new(title: title, image: image).call
      formatted_description = format_description(title, description)
      render json: { description: formatted_description }
    rescue Faraday::TooManyRequestsError
      render json: { error: "AI service overloaded. Try later." }, status: :too_many_requests
    rescue Faraday::UnauthorizedError
      render json: { error: "Invalid API Key." }, status: :unauthorized
    rescue StandardError => e
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

  private

  # --- CALLBACKS & HELPERS ---
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :description, :image, :ai_image_url, :public, :published_at)
  end

  def authorize_user
    redirect_to posts_path, alert: "Not authorized." unless current_user == @post.user
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

  # --- SCHEDULE WORDPRESS SYNC ---
  def schedule_sync(post)
    if post.published_at > Time.current
      PublishPostJob.set(wait_until: post.published_at).perform_later(post.id)
    else
      SyncToWordpressJob.perform_later(post.id)
    end
  end

  # --- FORMAT AI DESCRIPTION ---
  def format_description(title, description)
    return " " if description.blank?

    # Clean description
    clean_description = description.gsub(/^.*#{Regexp.escape(title)}.*$/i, '')
                                   .gsub(/^title:.*$/i, '')
                                   .gsub(/^introduction$/i, '')
                                   .strip

    # Title HTML
    title_html = "<h2><strong>#{title}</strong></h2>"

    # Paragraphs
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

    # Return
    "#{title_html}<div class='spacing'></div>#{formatted_paragraphs.join('<div class=\"spacing\"></div>')}"
  end
end
