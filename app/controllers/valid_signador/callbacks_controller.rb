# frozen_string_literal: true

module ValidSignador
  # Controller to handle callbacks from Signador service
  class CallbacksController < ApplicationController
    # Skip CSRF verification for callbacks from external service
    skip_before_action :verify_authenticity_token, only: [:create]

    # Receives the signed document from Signador service
    def create
      vote = Decidim::SignatureCollection::CandidaciesVote.find_by(signador_token: params[:token_id])
      token = vote.signador_token
      current_candidacy = vote.candidacy

      client = ValidSignador::Client.new(session: session)
      response = client.get_signature(token: token)

      if response["status"] == "OK"
        signed_document = Base64.decode64(response["signResult"])
        vote.update(encrypted_xml_doc_signed: Decidim::SignatureCollection::DataEncryptor.new(secret: Rails.application.secret_key_base).encrypt(signed_document))

        redirect_to Decidim::SignatureCollection::Engine.routes.url_helpers.finish_candidacy_signatures_path(current_candidacy)
      else
        flash[:alert] = I18n.t("decidim.signature_collection.candidacy_votes.signature_error", message: response["message"])
        redirect_to fill_personal_data_candidacy_signatures_path(current_candidacy)
      end
    end
  end
end
