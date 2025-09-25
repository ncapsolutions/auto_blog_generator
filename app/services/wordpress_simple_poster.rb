require "faraday"
require "json"
require "tempfile"
require "base64"

class WordpressSimplePoster
  def self.publish(post)
    new(
      site_url: Rails.application.credentials.dig(:wordpress, :site_url),
      username: Rails.application.credentials.dig(:wordpress, :username),
      app_password: Rails.application.credentials.dig(:wordpress, :app_password)
    ).publish(post)
  end

  def initialize(site_url:, username:, app_password:, timeout: 30)
    @site_url = site_url.chomp("/")
    @username = username
    @app_password = app_password
    @timeout = timeout
  end

  def publish(post)
    raise "Post must be public & published" unless post.public? && post.published?

    Rails.logger.info "🔹 [WP] Saving Post ##{post.id} to #{@site_url} as draft"
    Rails.logger.info "🔹 [WP] Using user: #{@username}"

    conn = Faraday.new(url: @site_url) do |f|
      f.options.timeout = @timeout
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    auth_header = "Basic #{Base64.strict_encode64("#{@username}:#{@app_password}")}"

    # --- Upload featured image ---
    featured_media_id = upload_featured_image(conn, auth_header, post)

    # --- Determine create or update ---
    if post.respond_to?(:wordpress_id) && post.wordpress_id.present?
      post_url = "#{@site_url}/wp-json/wp/v2/posts/#{post.wordpress_id}"
      method = :put
      Rails.logger.info "🔹 Updating WP Post ##{post.wordpress_id} (draft)"
    else
      post_url = "#{@site_url}/wp-json/wp/v2/posts"
      method = :post
      Rails.logger.info "🔹 Creating new WP Post (draft)"
    end

    # --- Always save as draft ---
    post_body = { 
      title: post.title, 
      content: post.description, 
      featured_media: featured_media_id,
      status: 'draft' # All posts saved as draft
    }

     # Get WordPress timezone (you might need to adjust this)
    # wp_timezone = ActiveSupport::TimeZone['UTC'] # Default to UTC
    
    # # Convert to WordPress timezone
    # wp_published_at = post.published_at.in_time_zone(wp_timezone)
    
    # if post.published_at > Time.current
    #   # For future posts
    #   post_body[:status] = 'future'
    #   post_body[:date] = wp_published_at.iso8601
    #   Rails.logger.info "🔹 Scheduled WP publish at #{post_body[:date]} (status: future)"
    # else
    #   # For immediate publishing
    #   post_body[:status] = 'publish'
    #   post_body[:date] = wp_published_at.iso8601
    #   Rails.logger.info "🔹 Instant WP publish (status: publish)"
    # end

    # Set scheduled date (for future posts)
    wp_timezone = ActiveSupport::TimeZone['UTC']
    wp_scheduled_at = post.published_at.in_time_zone(wp_timezone)
    post_body[:date] = wp_scheduled_at.iso8601

    Rails.logger.info "🔹 WP post will be saved as draft with scheduled date: #{post_body[:date]}"

    resp = conn.send(method, post_url) do |req|
      req.headers["Authorization"] = auth_header
      req.headers["Content-Type"] = "application/json"
      req.body = post_body.to_json
    end

    Rails.logger.info "🔹 WP post #{method.upcase} response: #{resp.status} #{resp.body}"

    if resp.success?
      JSON.parse(resp.body)
    else
      Rails.logger.error("❌ WP post #{method.upcase} failed: #{resp.status} #{resp.body}")
      nil
    end
  rescue => e
    Rails.logger.error("❌ WordpressSimplePoster error: #{e.full_message}")
    nil
  end

  private

  def upload_featured_image(conn, auth_header, post)
    return nil unless post.image.attached?

    featured_media_id = nil
    tmp = Tempfile.new(["wp-upload", File.extname(post.image.filename.to_s)], binmode: true)
    
    begin
      tmp.write(post.image.download)
      tmp.rewind

      media_url = "#{@site_url}/wp-json/wp/v2/media"

      resp = conn.post(media_url) do |req|
        req.headers["Authorization"] = auth_header
        req.headers["Content-Disposition"] = "attachment; filename=\"#{post.image.filename}\""
        req.body = { file: Faraday::UploadIO.new(tmp.path, post.image.content_type, post.image.filename.to_s) }
      end

      if resp.success?
        parsed = JSON.parse(resp.body)
        featured_media_id = parsed["id"]
        Rails.logger.info "✅ Featured image uploaded with ID: #{featured_media_id}"
      else
        Rails.logger.error("❌ WP media upload failed: #{resp.status} #{resp.body}")
      end
    ensure
      tmp.close
      tmp.unlink
    end

    featured_media_id
  end
end