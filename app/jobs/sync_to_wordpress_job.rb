# app/jobs/sync_to_wordpress_job.rb
class SyncToWordpressJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.public? && post.published?

    Rails.logger.info "🔹 Sync callback triggered for Post ##{post.id}"
    Rails.logger.info "🔹 public?: #{post.public?}, published?: #{post.published?}"

    # Prevent duplicate syncs using wordpress_id column
    if post.respond_to?(:wordpress_id) && post.wordpress_id.present?
      Rails.logger.info "⏩ Already synced to WordPress (ID: #{post.wordpress_id})"
      return
    end

    # Publish via service
    response = WordpressSimplePoster.publish(post)

    if response.present?
      Rails.logger.info "✅ Synced to WordPress: #{response['link'] || response['id']}"

      # Save WordPress post ID to prevent duplicate posts
      if post.respond_to?(:wordpress_id)
        post.update!(wordpress_id: response["id"])
      end
    else
      Rails.logger.warn "❌ Synced to WordPress: No response"
    end
  rescue => e
    Rails.logger.error("SyncToWordpressJob failed for post=#{post_id}: #{e.full_message}")
    raise
  end
end
