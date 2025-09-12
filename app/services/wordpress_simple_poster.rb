# app/services/wordpress_simple_poster.rb
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

  def initialize(site_url:, username:, app_password:, timeout:30)
    @site_url = site_url.chomp("/")  # e.g., "http://192.168.1.119/easysimunlocker_blogs"
    @username = username
    @app_password = app_password
    @timeout = timeout
  end

  def publish(post)
    raise "Post must be public & published" unless post.public? && post.published?

    conn = Faraday.new(url: @site_url) do |f|
      f.options.timeout = @timeout
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    auth_header = "Basic #{Base64.strict_encode64("#{@username}:#{@app_password}")}"

    # --- Upload featured image if present ---
    featured_media_id = nil
    if post.image.attached?
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
        else
          Rails.logger.error("WP media upload failed: #{resp.status} #{resp.body}")
        end
      ensure
        tmp.close
        tmp.unlink
      end
    end

    # --- Create the post on WordPress ---
    post_url = "#{@site_url}/wp-json/wp/v2/posts"
    post_body = {
      title: post.title,
      content: post.description,
      status: "publish",
      featured_media: featured_media_id
    }

    resp = conn.post(post_url) do |req|
      req.headers["Authorization"] = auth_header
      req.headers["Content-Type"] = "application/json"
      req.body = post_body.to_json
    end

    if resp.success?
      JSON.parse(resp.body)
    else
      Rails.logger.error("WP post create failed: #{resp.status} #{resp.body}")
      nil
    end
  rescue => e
    Rails.logger.error("WordpressSimplePoster error: #{e.full_message}")
    nil
  end
end
