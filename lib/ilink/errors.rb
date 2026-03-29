# frozen_string_literal: true

module ILink
  class Error < StandardError; end

  # Raised on non-2xx HTTP responses
  class ApiError < Error
    attr_reader :status, :body

    def initialize(status, body)
      @status = status
      @body   = body
      super("iLink API error #{status}: #{body}")
    end
  end

  # Raised when long-poll times out.
  class TimeoutError < Error; end

  # Raised on authentication failures (401/403)
  class AuthenticationError < ApiError; end
end
