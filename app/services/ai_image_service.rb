require "open-uri"

class AiImageService
  def self.generate(prompt:)
    client = OpenAI::Client.new
    response = client.images.generate(
      parameters: { prompt: prompt, n: 1, size: "512x512" }
    )
    url = response.dig("data", 0, "url")
    raise "Failed to generate image" unless url
    url
  end

  def self.attach_to_post(post, image_url, filename: "ai_image.png")
    downloaded_image = URI.open(image_url)
    post.image.attach(io: downloaded_image, filename: filename)
  rescue => e
    raise "Failed to attach AI image: #{e.message}"
  end
end
