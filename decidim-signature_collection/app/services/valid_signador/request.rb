# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "openssl"
require "base64"

module ValidSignador
  # HTTP request handler with HMAC SHA256 authentication
  class Request
    attr_reader :config

    def initialize(config)
      @config = config
    end

    # Perform a GET request
    def get(path)
      uri = URI("#{config.base_url}#{path}")
      http = build_http(uri)

      request = Net::HTTP::Get.new(uri)
      add_auth_headers(request)

      handle_response(http.request(request))
    end

    # Perform a POST request
    def post(path, payload)
      uri = URI("#{config.base_url}#{path}")
      http = build_http(uri)

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Origin"] = config.domain
      request.body = payload.to_json

      handle_response(http.request(request))
    end

    private

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 10
      http.read_timeout = 30
      http
    end

    def add_auth_headers(request)
      date = Time.current.strftime("%d/%m/%Y %H:%M")
      request["Date"] = date
      request["Origin"] = config.domain
      request["Authorization"] = "SC #{hmac_signature(date)}"
    end

    def hmac_signature(date)
      data = "#{config.domain}_#{date}"
      digest = OpenSSL::HMAC.digest("SHA256", config.api_key, data)
      Base64.strict_encode64(digest)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        parse_json_response(response)
      when Net::HTTPUnauthorized
        raise AuthenticationError, "Authentication failed: #{response.message}"
      when Net::HTTPClientError
        raise ApiError, "Client error (#{response.code}): #{response.body}"
      when Net::HTTPServerError
        raise ApiError, "Server error (#{response.code}): #{response.message}"
      else
        raise ApiError, "Unexpected response (#{response.code}): #{response.message}"
      end
    end

    def parse_json_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise InvalidResponseError, "Invalid JSON response: #{e.message}"
    end
  end
end
