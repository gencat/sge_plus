# frozen_string_literal: true

module ValidSignador
  # Main client for interacting with Signador service
  class Client
    attr_reader :config, :session

    # Initialize the client
    #
    # @param session [ActionDispatch::Request::Session] Rails session for state management
    def initialize(session: nil)
      @config = Configuration.new
      @session = session
    end

    # Initialize a signing process and get a token
    #
    # @return [Hash] Response with token
    # @raise [ApiError] if the request fails
    def init_process
      request = Request.new(config)
      response = request.get("/signador/initProcess")

      validate_response!(response)
      response
    end

    # Start the signing process with document and configuration
    #
    # @param token [String] Token from initProcess
    # @param document [String] XML document to sign
    # @param options [Hash] Additional options for PayloadBuilder
    # @return [Hash] Response from Signador
    # @raise [ApiError] if the request fails
    def start_sign_process(token:, document:, options: {})
      # Store process state in session if available
      if session
        store_process_state(
          token: token,
          document_original: document,
          candidacy_id: options[:candidacy_id],
          user_id: options[:user_id],
          redirect_url: options[:final_redirect_url]
        )
      end

      payload = PayloadBuilder.new(
        token: token,
        document: document,
        options: options
      ).build

      request = Request.new(config)
      response = request.post("/signador/startSignProcess", payload)

      validate_response!(response)
      response
    end

    # Get the signature result
    #
    # @param token [String] Token identifying the signature process
    # @return [Hash] Response with signed document
    # @raise [ApiError] if the request fails
    def get_signature(token:)
      request = Request.new(config)
      response = request.get("/signador/getSignature?identificador=#{token}")

      validate_response!(response)
    end

    # Build the URL for user to sign the document
    #
    # @param token [String] Token from initProcess
    # @return [String] URL to redirect user to
    def sign_url(token:)
      "#{config.base_url}/signador/?id=#{token}"
    end

    # Retrieve stored process state from session
    #
    # @return [Hash, nil] Stored process state or nil
    def process_state
      return nil unless session

      session[:valid_signador_process]
    end

    # Clear stored process state from session
    def clear_process_state!
      return unless session

      session.delete(:valid_signador_process)
    end

    private

    def validate_response!(response)
      raise InvalidResponseError, "Response is not a hash: #{response.inspect}" unless response.is_a?(Hash)

      if response["status"] == "KO"
        error_message = response["message"] || "Unknown error"
        raise ApiError, "Signador API error: #{error_message}"
      end

      true
    end

    def store_process_state(token:, document_original:, candidacy_id: nil, user_id: nil, redirect_url: nil)
      session[:valid_signador_process] = {
        token: token,
        candidacy_id: candidacy_id,
        document_original: document_original,
        timestamp_inici: Time.current.iso8601,
        user_id: user_id,
        redirect_url: redirect_url
      }
    end
  end
end
