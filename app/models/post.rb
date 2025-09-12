class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  # Virtual attribute for AI image (optional)
  attr_accessor :ai_image_url

  # --- VALIDATIONS ---
  validates :title, presence: true
  validates :description, presence: true

  # --- SCOPES ---
  scope :public_posts, -> { where(public: true) }
  scope :by_user, ->(user) { where(user: user) }
  scope :published, -> { where('published_at IS NULL OR published_at <= ?', Time.current.utc) }

  # --- HELPERS ---
  def published?
    published_at.nil? || published_at <= Time.current.utc
  end

  private

  def attach_ai_image(post)
    if ai_image_url.present?
      post.image.attach(io: URI.open(ai_image_url), filename: "ai_image.jpg")
    end
  end
end
