class SyncToWordpressJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    Rails.logger.info "🔹 SyncToWordpressJob for Post ##{post.id}"
    response = WordpressSimplePoster.publish(post)
    Rails.logger.info "🔹 WP Publish Response: #{response.inspect}"

    if response.present? && post.respond_to?(:wordpress_id)
      post.update!(wordpress_id: response["id"])
      Rails.logger.info "✅ WordPress ID saved: #{response['id']}"
    else
      Rails.logger.warn "❌ WP sync failed for Post ##{post.id}"
    end
  rescue => e
    Rails.logger.error("❌ SyncToWordpressJob failed for post=#{post_id}: #{e.full_message}")
    raise
  end
end
