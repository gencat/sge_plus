# frozen_string_literal: true

# Load all service classes
require_relative "valid_signador/error"
require_relative "valid_signador/configuration"
require_relative "valid_signador/request"
require_relative "valid_signador/payload_builder"
require_relative "valid_signador/client"

module ValidSignador
  # Base error class for ValidSignador service
  class Error < StandardError; end

  # Raised when authentication fails
  class AuthenticationError < Error; end

  # Raised when the Signador API returns an error
  class ApiError < Error; end

  # Raised when the response format is invalid
  class InvalidResponseError < Error; end

  # Raised when the configuration is missing or invalid
  class ConfigurationError < Error; end

  # Raised when the token has expired
  class TokenExpiredError < Error; end
end
