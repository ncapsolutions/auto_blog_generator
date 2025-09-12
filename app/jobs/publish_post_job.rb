class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    # No need to update anything if already visible, just placeholder
    Rails.logger.info "Post ##{post.id} scheduled publish executed at #{Time.current}"

    if post.public? && post.published?
      # enqueue sync job
      SyncToWordpressJob.perform_later(post.id)
    end
  end
end