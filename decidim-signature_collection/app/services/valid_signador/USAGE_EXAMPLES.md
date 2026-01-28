# frozen_string_literal: true

# Example usage of the ValidSignador client for signing candidacy XML documents
#
# This file shows how to integrate electronic signature in the flow
# of creating/managing candidacies using the Consorci AOC Signador service.

```ruby
module Decidim
  module SignatureCollection
    # Example controller that uses ValidSignador to sign XML documents
    class CandidacySignaturesExampleController < ApplicationController
      before_action :authenticate_user!
      before_action :load_candidacy

      # Initiates the signature process for a candidacy XML document
      def new
        # Render view with "Sign with digital certificate" button
      end

      # Creates the XML document and initiates the signature process
      def create
        # 1. Generate the candidacy XML document
        xml_document = generate_candidacy_xml

        # 2. Initialize the client with the current session
        client = ValidSignador::Client.new(session: session)

        # 3. Obtain a token from the Signador service
        init_response = client.init_process
        token = init_response["token"]

        # 4. Configure and start the signature process
        client.start_sign_process(
          token: token,
          document: xml_document,
          options: {
            candidacy_id: @candidacy.id,
            final_redirect_url: candidacy_signed_path(@candidacy),
            description: "Electronic signature of candidacy '#{@candidacy.title}'",
            doc_name: "candidacy_#{@candidacy.id}_#{Time.current.to_i}.xml",
            hash_algorithm: "SHA-256" # Optional, default is already SHA-256
          }
        )

        # 5. Redirect the user to the Signador service to sign
        redirect_to client.sign_url(token: token), allow_other_host: true
      rescue ValidSignador::ConfigurationError => e
        Rails.logger.error("ValidSignador configuration error: #{e.message}")
        redirect_to @candidacy, alert: "Signature service configuration error"
      rescue ValidSignador::AuthenticationError => e
        Rails.logger.error("ValidSignador authentication error: #{e.message}")
        redirect_to @candidacy, alert: "Authentication error with signature service"
      rescue ValidSignador::ApiError => e
        Rails.logger.error("ValidSignador API error: #{e.message}")
        redirect_to @candidacy, alert: "Error communicating with signature service"
      rescue StandardError => e
        Rails.logger.error("Unexpected signature error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        redirect_to @candidacy, alert: "Error initializing signature process"
      end

      # GET /candidacies/:candidacy_id/signed
      # Confirmation page after signing (redirect from callback)
      def signed
        # The user arrives here after ValidSignador::CallbacksController
        # processes the signed document
        flash.now[:notice] = "The document has been signed successfully"
      end

      private

      def load_candidacy
        @candidacy = Decidim::SignatureCollection::Candidacy.find(params[:candidacy_id])
      end

      def generate_candidacy_xml
        # Example of generating an XML document with candidacy data
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.candidacy(xmlns: "http://example.cat/candidacy") do
            xml.id @candidacy.id
            xml.title @candidacy.title["ca"]
            xml.description @candidacy.description["ca"]
            xml.author do
              xml.name @candidacy.author.name
              xml.email @candidacy.author.email
            end
            xml.created_at @candidacy.created_at.iso8601
            xml.signature_type @candidacy.signature_type
            xml.scope do
              xml.id @candidacy.scope&.id
              xml.name @candidacy.scope&.name&.dig("ca")
            end
            xml.metadata do
              xml.signed_by current_user.name
              xml.signed_at Time.current.iso8601
            end
          end
        end

        builder.to_xml
      end
    end
  end
end

# Example usage in a Rake task or service for processing signatures in bulk
module Decidim
  module SignatureCollection
    class BulkSignatureService
      def initialize(candidacies, user)
        @candidacies = candidacies
        @user = user
      end

      def call
        @candidacies.each do |candidacy|
          sign_candidacy(candidacy)
        end
      end

      private

      def sign_candidacy(candidacy)
        # Note: In a batch process without web session, you would need to
        # implement a different state storage mechanism
        # (for example, a database table)

        xml_document = generate_candidacy_xml(candidacy)

        # Create a hash to store the state temporarily
        temp_session = {}
        client = ValidSignador::Client.new(session: temp_session)

        init_response = client.init_process
        token = init_response["token"]

        client.start_sign_process(
          token: token,
          document: xml_document,
          options: {
            candidacy_id: candidacy.id,
            user_id: @user.id,
            description: "Batch signature of candidacy #{candidacy.id}"
          }
        )

        # Here you would need to implement a mechanism to store
        # the token and state in the database
        store_signature_process(candidacy, token, temp_session[:valid_signador_process])
      rescue ValidSignador::Error => e
        Rails.logger.error("Error signing candidacy #{candidacy.id}: #{e.message}")
      end

      def generate_candidacy_xml(candidacy)
        # Similar to the previous example
        # ...
      end

      def store_signature_process(candidacy, token, process_state)
        # Example: create a database record
        # SignatureProcess.create!(
        #   candidacy: candidacy,
        #   token: token,
        #   process_state: process_state.to_json,
        #   status: :pending
        # )
      end
    end
  end
end

# Example of how to check the status of a signature
module Decidim
  module SignatureCollection
    class CheckSignatureStatusService
      def initialize(token)
        @token = token
        @client = ValidSignador::Client.new
      end

      def call
        response = @client.get_signature(token: @token)

        if response["status"] == "OK"
          signed_document = decode_signature_result(response["signResult"])
          save_signed_document(signed_document)
          { status: :success, document: signed_document }
        else
          { status: :error, message: response["error"] }
        end
      rescue ValidSignador::Error => e
        Rails.logger.error("Error checking signature: #{e.message}")
        { status: :error, message: e.message }
      end

      private

      def decode_signature_result(sign_result)
        if sign_result.start_with?("http://", "https://")
          # If it's a URL, you need to make an HTTP request to get the document
          fetch_from_url(sign_result)
        else
          # If it's base64, decode it
          Base64.decode64(sign_result)
        end
      end

      def fetch_from_url(url)
        # Implement logic to fetch the document from the URL
      end

      def save_signed_document(document)
        # Implement logic to save the signed document
        # (ActiveStorage, filesystem, etc.)
      end
    end
  end
end
```ruby
