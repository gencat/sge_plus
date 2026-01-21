# frozen_string_literal: true

module ValidSignador
  # Controller to handle callbacks from Signador service
  class CallbacksController < ApplicationController
    # Skip CSRF verification for callbacks from external service
    skip_before_action :verify_authenticity_token, only: [:create]

    # Receives the signed document from Signador service
    def create
      vote = Decidim::SignatureCollection::CandidaciesVote.find_by(signador_token: params[:token])
      token = vote.signador_token
      current_candidacy = vote.candidacy
      
      client = ValidSignador::Client.new(session: session)
      response = client.get_signature(token: token)

      if response["status"] == "OK"
        signed_document = response["signResult"]
        vote.update(encrypted_xml_doc_signed: Decidim::SignatureCollection::DataEncryptor.new(secret: Rails.application.secret_key_base).encrypt(signed_document))

        finish_candidacy_signatures_path(current_candidacy)
      else
        flash[:alert] = "Error obtenint la signatura: #{response['message']}"
        redirect_to fill_personal_data_path
      end

      
      # process_state = retrieve_process_state
      
      # if process_state.nil?
      #   render_error("No s'ha trobat l'estat del procés de signatura", :not_found)
      #   return
    #   end
      
    #   # Validate token matches
    #   unless params[:token] == process_state[:token]
    #     render_error("El token no coincideix", :unprocessable_entity)
    #     return
    #   end
      
    #   # Check if signature was successful
    #   if params[:status] == "KO"
    #     error_message = params[:error] || "Error desconegut en el procés de signatura"
    #     handle_signature_error(process_state, error_message)
    #     return
    #   end
      
    #   # Get the signed document
    #   signed_result = params[:signResult]
      
    #   if signed_result.blank?
    #     render_error("No s'ha rebut el document signat", :unprocessable_entity)
    #     return
    #   end
    #   byebug

    #   # Process the signed document
    #   process_signed_document(process_state, signed_result)
    # rescue StandardError => e
    #   Rails.logger.error("Error processing Signador callback: #{e.message}")
    #   Rails.logger.error(e.backtrace.join("\n"))
    #   render_error("Error processant la resposta del Signador: #{e.message}", :internal_server_error)
    end

    private

    def retrieve_process_state
      session[:valid_signador_process]
    end

    def clear_process_state!
      session.delete(:valid_signador_process)
    end

    def process_signed_document(process_state, signed_result)
      # Decode the signed document if it's base64 encoded
      signed_document = decode_signature_result(signed_result)

      # Store or process the signed document
      # This is where you would save the signed document to your database
      # or perform any additional processing

      Rails.logger.info("Signed document received for token: #{process_state[:token]}")
      Rails.logger.info("User ID: #{process_state[:user_id]}")
      Rails.logger.info("Candidacy ID: #{process_state[:candidacy_id]}")

      # Clear the process state from session
      clear_process_state!

      # Redirect to the original URL or a success page
      redirect_url = process_state[:redirect_url] || root_path
      redirect_to redirect_url, notice: "Document signat correctament"
    end

    def handle_signature_error(process_state, error_message)
      Rails.logger.error("Signature error: #{error_message}")

      # Clear the process state
      clear_process_state!

      # Redirect with error message
      redirect_url = process_state[:redirect_url] || root_path
      redirect_to redirect_url, alert: "Error en la signatura: #{error_message}"
    end

    def decode_signature_result(signed_result)
      # If the result is a URL, we need to fetch it
      if signed_result.start_with?("http://", "https://")
        fetch_signed_document_from_url(signed_result)
      else
        # Otherwise, it's base64 encoded
        Base64.decode64(signed_result)
      end
    rescue StandardError => e
      Rails.logger.error("Error decoding signature result: #{e.message}")
      signed_result
    end

    def fetch_signed_document_from_url(url)
      # This is a placeholder - you might want to use the ValidSignador::Client
      # to fetch the document using get_signature instead
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      raise "Failed to fetch signed document from URL: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def render_error(message, status)
      respond_to do |format|
        format.html { redirect_to root_path, alert: message }
        format.json { render json: { error: message }, status: status }
      end
    end
  end
end
