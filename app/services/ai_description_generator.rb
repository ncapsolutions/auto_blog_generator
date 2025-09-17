class AiDescriptionGenerator
  require "openai"

  def initialize(title:, image: nil, keywords: [], links: [])
    @title = title
    @image = image
    @keywords = keywords || []
    @links = links || []
    @client = OpenAI::Client.new
  end

  def call
    retries = 0
    begin
      prompt = <<~PROMPT
        Write a detailed, engaging article about "#{@title}".

        Requirements:
        - Use ALL of these keywords at least once in natural sentences:
          #{@keywords.join(", ")}
        - Integrate keywords smoothly in paragraphs, not as a list.
        - Minimum 4-5 paragraphs, with headings/subheadings if possible.
        - Friendly, natural, human-like tone.
        - Avoid repeating the title at the beginning.
        - End with a short conclusion or call-to-action.

      PROMPT

      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [{ role: "user", content: prompt }],
          max_tokens: 700
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue Faraday::TooManyRequestsError
      retries += 1
      if retries < 3
        sleep_time = 2**retries
        sleep sleep_time
        retry
      else
        "AI service is overloaded. Please try again later."
      end
    rescue Faraday::UnauthorizedError
      "Invalid API Key or Unauthorized request."
    rescue => e
      Rails.logger.error("AI Description Error: #{e.message}")
      "Unexpected error while generating description."
    end
  end
end
