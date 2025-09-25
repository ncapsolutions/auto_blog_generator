class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    Rails.logger.info "🔹 PublishPostJob executing for Post ##{post.id} at #{Time.current}"

    if post.public? && post.published?
      SyncToWordpressJob.perform_later(post.id)
      Rails.logger.info "🔹 Enqueued SyncToWordpressJob for Post ##{post.id}"
    end
  end
end
