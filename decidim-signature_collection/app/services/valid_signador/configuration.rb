# frozen_string_literal: true

module ValidSignador
  # Configuration class for ValidSignador service
  class Configuration
    attr_accessor :domain, :api_key, :base_url, :callback_path

    def initialize
      @domain = ENV.fetch("SIGNADOR_DOMAIN", nil)
      @api_key = ENV.fetch("SIGNADOR_API_KEY", nil)
      @base_url = ENV.fetch("SIGNADOR_BASE_URL", nil)
      @callback_path = ENV.fetch("SIGNADOR_CALLBACK_PATH", "/valid_signador/callback")

      validate!
    end

    def callback_url
      return nil unless domain

      "#{domain}#{callback_path}"
    end

    private

    def validate!
      raise ConfigurationError, "SIGNADOR_DOMAIN is required" if domain.blank?
      raise ConfigurationError, "SIGNADOR_BASE_URL is required" if base_url.blank?
      raise ConfigurationError, "SIGNADOR_API_KEY is required" if api_key.blank?
    end
  end
end
