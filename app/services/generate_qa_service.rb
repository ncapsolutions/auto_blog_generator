# app/services/ai_qa_generator.rb
class GenerateQaService
  require "openai"

  MIN_QA = 3
  MAX_QA = 5

  def initialize(title:, keywords: [], links: [])
    @title = title
    @keywords = keywords || []
    @links = links || []
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    return [] if @title.blank? && @keywords.empty?

    retries = 0
    begin
      prompt = <<~PROMPT
        You are a helpful assistant. Based on the following post details, generate #{MIN_QA}-#{MAX_QA} concise Q&A pairs.

        Title: #{@title}
        Keywords: #{@keywords.join(", ")}
        Links: #{@links.join(", ")}

        Output format: JSON array like:
        [
          {"q": "Question 1", "a": "Answer 1"},
          {"q": "Question 2", "a": "Answer 2"},
          ...
        ]
      PROMPT

      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7,
          max_tokens: 500
        }
      )

      ai_text = response.dig("choices", 0, "message", "content")
      parse_ai_response(ai_text)
    rescue Faraday::TooManyRequestsError
      retries += 1
      if retries < 3
        sleep_time = 2**retries
        sleep sleep_time
        retry
      else
        []
      end
    rescue Faraday::UnauthorizedError
      []
    rescue => e
      Rails.logger.error("AI Q&A Error: #{e.message}")
      []
    end
  end

  private

  def parse_ai_response(ai_text)
    return [] if ai_text.blank?

    JSON.parse(ai_text).map do |item|
      { q: item["q"].to_s.strip, a: item["a"].to_s.strip }
    end.first(MAX_QA)
  rescue JSON::ParserError, TypeError => e
    Rails.logger.error("Failed to parse AI Q&A response: #{e.message}")
    []
  end
end
