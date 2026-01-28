# frozen_string_literal: true

module ValidSignador
  # Builds JSON payload for Signador API requests
  class PayloadBuilder
    attr_reader :token, :document, :options

    # Initialize the payload builder
    #
    # @param token [String] Token obtained from initProcess
    # @param document [String] XML document to sign
    # @param options [Hash] Additional options
    # @option options [String] :redirect_url URL to redirect after signing
    # @option options [String] :description Description of the signature operation
    # @option options [String] :doc_name Document name (default: "document.xml")
    # @option options [String] :hash_algorithm Hash algorithm (default: "SHA-256")
    # @option options [Boolean] :response_b64 Return signature in base64 (default: true)
    def initialize(token:, document:, options: {})
      @token = token
      @document = document
      @options = options
    end

    # Build the JSON payload for startSignProcess
    #
    # @return [Hash] JSON payload
    def build
      {
        redirectUrl: redirect_url,
        token: token,
        descripcio: description,
        responseB64: response_b64,
        applet_cfg: applet_config
      }
    end

    private

    def redirect_url
      options[:redirect_url] || "/valid_signador/callback"
    end

    def description
      options[:description] || "Signatura de document XML"
    end

    def response_b64
      options.fetch(:response_b64, "true").to_s
    end

    def applet_config
      {
        keystore_type: 0, # Generic keystore
        signature_mode: 13, # XAdES-T enveloped with timestamp
        doc_type: 4, # B64fileContent - full document in base64
        doc_name: doc_name,
        document_to_sign: encode_document,
        hash_algorithm: hash_algorithm,
        xml_cfg: xml_config
      }
    end

    def doc_name
      options[:doc_name] || "document.xml"
    end

    def hash_algorithm
      options[:hash_algorithm] || "SHA-256"
    end

    def encode_document
      Base64.strict_encode64(document)
    end

    def xml_config
      {
        includeXMLTimestamp: "true", # Include qualified timestamp
        canonicalizationWithComments: "false",
        protectKeyInfo: "false"
      }
    end
  end
end
