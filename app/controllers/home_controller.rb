class HomeController < ApplicationController
  def index
     @posts = Post.public_posts.published.order(created_at: :desc)
  end
end
