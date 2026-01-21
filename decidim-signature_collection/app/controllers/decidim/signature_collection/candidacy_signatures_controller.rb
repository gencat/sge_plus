# frozen_string_literal: true

# i18n-tasks-use t('layouts.decidim.candidacy_signature_creation_header.fill_personal_data')
# i18n-tasks-use t('layouts.decidim.candidacy_signature_creation_header.finish')
module Decidim
  module SignatureCollection
    class CandidacySignaturesController < Decidim::SignatureCollection::ApplicationController
      layout "layouts/decidim/candidacy_signature_creation"

      include Decidim::SignatureCollection::NeedsCandidacy
      include Decidim::FormFactory

      prepend_before_action :set_wizard_steps
      before_action :authorize_wizard_step

      helper CandidacyHelper

      helper_method :candidacy_type, :extra_data_legal_information

      def index
        redirect_to fill_personal_data_path
      end

      def fill_personal_data
        @form = form(Decidim::SignatureCollection::VoteForm)
                .from_params(
                  candidacy: current_candidacy
                )
      end

      def store_personal_data
        build_vote_form(params)

        if @vote_form.invalid?
          flash[:alert] = I18n.t("personal_data.invalid", scope: "decidim.signature_collection.candidacy_votes")
          @form = @vote_form

          render :fill_personal_data
        else
          if params.has_key?(:candidacies_vote)
            build_vote_form(params)
          else
            check_session_personal_data
          end

          VoteCandidacy.call(@vote_form) do
            on(:ok) do |vote|
              session[:candidacy_vote_form] = {}

              xml_document = vote.encrypted_xml_doc_to_sign
              decrypted_xml = Decidim::SignatureCollection::DataEncryptor.new(secret: Rails.application.secret_key_base).decrypt(xml_document)
              base64_xml = Base64.strict_encode64(decrypted_xml)
      
              client = ValidSignador::Client.new(session: session)
              init_response = client.init_process
              token = init_response["token"]

              vote.update!(signador_token: token)

              client.start_sign_process(
                token: token,
                document: base64_xml,
                options: {
                  candidacy_id: candidacy.id,
                  user_id: nil,
                  final_redirect_url: main_app.valid_signador_callback_url,
                  description: "Signatura electrònica de la candidatura '#{translated_attribute(candidacy.title)}'",
                  doc_name: vote.filename,
                  hash_algorithm: "SHA-256"
                }
                )

              redirect_to client.sign_url(token: token), allow_other_host: true
            end

            on(:invalid) do |vote|
              logger.fatal "Failed creating signature: #{vote.errors.full_messages.join(", ")}" if vote
              flash[:alert] = I18n.t("create.invalid", scope: "decidim.signature_collection.candidacy_votes")
              redirect_to send(:fill_personal_data_path)
            end 
          end
        end
      end

      private

      attr_reader :wizard_steps

      def fill_personal_data_path
        fill_personal_data_candidacy_signatures_path(current_candidacy)
      end

      def finish_path
        token = params[:token_id]
        vote = params[:vote_id]

        client = ValidSignador::Client.new(session: session)
        token = "1818f392-76c7-4813-9736-4ccb0aa244f3"

        # https://signador-pre.aoc.cat/signador/getSignature?identificador=token

        response = client.get_signature(token: token)
        
        if response["status"] == "OK"
          signed_document = response["signResult"]
          vote.update(encrypted_xml_doc_signed: Decidim::SignatureCollection::DataEncryptor.new(secret: Rails.application.secret_key_base).encrypt(signed_document))

          finish_candidacy_signatures_path(current_candidacy)
        else
          flash[:alert] = "Error obtenint la signatura: #{response['message']}"
          redirect_to fill_personal_data_path
        end
      end

      def build_vote_form(parameters)
        @vote_form = form(Decidim::SignatureCollection::VoteForm).from_params(parameters).tap do |form|
          form.candidacy = current_candidacy
        end

        session[:candidacy_vote_form] ||= {}
        session[:candidacy_vote_form] = session[:candidacy_vote_form].merge(@vote_form.attributes_with_values.except(:candidacy))
      end

      def candidacy_type
        @candidacy_type ||= current_candidacy&.scoped_type&.type
      end

      def authorize_wizard_step
        enforce_permission_to :sign_candidacy, :candidacy, candidacy: current_candidacy
      end

      def set_wizard_steps
        @wizard_steps = [:finish]
        @wizard_steps.unshift(:fill_personal_data)
      end

      def extra_data_legal_information
        @extra_data_legal_information ||= candidacy_type.extra_fields_legal_information
      end

      def session_vote_form
        attributes = session[:candidacy_vote_form].merge(candidacy: current_candidacy)

        @vote_form = form(Decidim::SignatureCollection::VoteForm).from_params(attributes)
      end

      def check_session_personal_data
        return if session[:candidacy_vote_form].present? && session_vote_form&.valid?

        flash[:alert] = I18n.t("create.error", scope: "decidim.signature_collection.candidacy_votes")
        redirect_to fill_personal_data_path
      end
    end
  end
end
