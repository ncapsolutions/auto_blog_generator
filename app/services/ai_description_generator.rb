# app/services/ai_description_generator.rb
class AiDescriptionGenerator
  require "openai"

  def initialize(title:, image: nil)
    @title = title
    @image = image
    @client = OpenAI::Client.new
  end

  def call
    retries = 0
    begin
      prompt = <<~PROMPT
        Write a complete, human-like article for the following title: "#{@title}".
        Requirements:
        - At least 4-5 paragraphs.
        - Include subheadings where appropriate.
        - Include bullet points or numbered lists if it makes sense.
        - Write in a friendly, natural style, as if a human wrote it.
        - Make it informative and easy to read.
        - Avoid sounding robotic or repetitive.
        - Optionally, include a short conclusion or call-to-action at the end.
      PROMPT

      prompt += " Include this image in context: #{@image}" if @image.present?

      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 600
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue Faraday::TooManyRequestsError
      retries += 1
      if retries < 3
        sleep_time = 2**retries
        Rails.logger.warn("Too many requests. Retrying in #{sleep_time}s...")
        sleep sleep_time
        retry
      else
        "AI service is currently overloaded. Please try again later."
      end
    rescue Faraday::UnauthorizedError
      "Invalid API Key or Unauthorized request."
    rescue => e
      Rails.logger.error("AI Description Error: #{e.message}")
      "An unexpected error occurred while generating the description."
    end
  end
end
