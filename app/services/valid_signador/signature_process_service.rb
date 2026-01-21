# frozen_string_literal: true

module ValidSignador
  class SignatureProcessService
    def initialize(vote:, candidacy:, session:, url_helpers:)
      @vote = vote
      @candidacy = candidacy
      @session = session
      @url_helpers = url_helpers
    end

    def call
      prepare_document
      init_signador_process
      start_sign_process
      
      { success: true, sign_url: @sign_url }
    rescue => e
      { success: false, error: e.message }
    end

    private

    def prepare_document
      xml_document = @vote.encrypted_xml_doc_to_sign
      @decrypted_xml = Decidim::SignatureCollection::DataEncryptor.new(
        secret: Rails.application.secret_key_base
      ).decrypt(xml_document)
    end

    def init_signador_process
      @client = ValidSignador::Client.new(session: @session)
      init_response = @client.init_process
      @token = init_response["token"]
      @vote.update!(signador_token: @token)
    end

    def start_sign_process
      @client.start_sign_process(
        token: @token,
        document: @decrypted_xml,
        options: sign_options
      )
      @sign_url = @client.sign_url(token: @token)
    end

    def sign_options
      {
        candidacy_id: @candidacy.id,
        user_id: nil,
        final_redirect_url: @url_helpers.valid_signador_callback_url,
        description: I18n.t(
          "decidim.signature_collection.candidacy_votes.sign_description",
          title: translated_attribute(@candidacy.title)
        ),
        doc_name: @vote.filename,
        hash_algorithm: "SHA-256"
      }
    end

    def translated_attribute(attribute)
      attribute.is_a?(Hash) ? attribute[I18n.locale.to_s] || attribute.values.first : attribute
    end
  end
end
