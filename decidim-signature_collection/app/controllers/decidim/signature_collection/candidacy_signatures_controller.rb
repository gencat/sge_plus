# frozen_string_literal: true

# i18n-tasks-use t('layouts.decidim.candidacy_signature_creation_header.fill_personal_data')
# i18n-tasks-use t('layouts.decidim.candidacy_signature_creation_header.finish')
# i18n-tasks-use t('layouts.decidim.candidacy_signature_creation_header.sms_code')
# i18n-tasks-use t('layouts.decidim.candidacy_signature_creation_header.sms_phone_number')
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

      # POST /candidacies/:candidacy_id/candidacy_signatures
      def create
        enforce_permission_to :vote, :candidacy, candidacy: current_candidacy

        @form = form(Decidim::SignatureCollection::VoteForm)
                .from_params(
                  candidacy: current_candidacy,
                  signer: current_user
                )

        VoteCandidacy.call(@form) do
          on(:ok) do
            current_candidacy.reload
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render :error_on_vote, status: :unprocessable_entity
          end
        end
      end

      def fill_personal_data
        @form = form(Decidim::SignatureCollection::VoteForm)
                .from_params(
                  candidacy: current_candidacy,
                  signer: current_user
                )
      end

      def store_personal_data
        build_vote_form(params)

        if @vote_form.invalid?
          flash[:alert] = I18n.t("personal_data.invalid", scope: "decidim.signature_collection.candidacy_votes")
          @form = @vote_form

          render :fill_personal_data
        else
          redirect_to sms_phone_number_path
        end
      end

      def sms_phone_number
        redirect_to(finish_path) && return unless sms_step?

        @form = Decidim::Verifications::Sms::MobilePhoneForm.new
      end

      def store_sms_phone_number
        redirect_to(finish_path) && return unless sms_step?

        @form = Decidim::Verifications::Sms::MobilePhoneForm.from_params(params.merge(user: current_user))

        ValidateMobilePhone.call(@form, current_user) do
          on(:ok) do |metadata|
            store_session_sms_code(metadata)
            redirect_to sms_code_path
          end

          on(:invalid) do
            flash[:alert] = I18n.t("sms_phone.invalid", scope: "decidim.signature_collection.candidacy_votes")
            render :sms_phone_number
          end
        end
      end

      def sms_code
        redirect_to(finish_path) && return unless sms_step?

        redirect_to sms_phone_number_path && return if session_sms_code.blank?

        @form = Decidim::Verifications::Sms::ConfirmationForm.new
      end

      def store_sms_code
        redirect_to(finish_path) && return unless sms_step?

        @form = Decidim::Verifications::Sms::ConfirmationForm.from_params(params)
        ValidateSmsCode.call(@form, session_sms_code) do
          on(:ok) do
            clear_session_sms_code
            redirect_to finish_path
          end

          on(:invalid) do
            flash[:alert] = I18n.t("sms_code.invalid", scope: "decidim.signature_collection.candidacy_votes")
            render :sms_code
          end
        end
      end

      def finish
        if params.has_key?(:candidacies_vote) || !fill_personal_data_step?
          build_vote_form(params)
        else
          check_session_personal_data
        end

        VoteCandidacy.call(@vote_form) do
          on(:ok) do
            session[:candidacy_vote_form] = {}
          end

          on(:invalid) do |vote|
            logger.fatal "Failed creating signature: #{vote.errors.full_messages.join(", ")}" if vote
            flash[:alert] = I18n.t("create.invalid", scope: "decidim.signature_collection.candidacy_votes")
            redirect_to send(:fill_personal_data_path)
          end
        end
      end

      private

      attr_reader :wizard_steps

      def fill_personal_data_path
        fill_personal_data_candidacy_signatures_path(current_candidacy)
      end

      def sms_code_path
        sms_code_candidacy_signatures_path(current_candidacy)
      end

      def finish_path
        finish_candidacy_signatures_path(current_candidacy)
      end

      def sms_phone_number_path
        sms_phone_number_candidacy_signatures_path(current_candidacy)
      end

      def build_vote_form(parameters)
        @vote_form = form(Decidim::SignatureCollection::VoteForm).from_params(parameters).tap do |form|
          form.candidacy = current_candidacy
          form.signer = current_user
        end

        session[:candidacy_vote_form] ||= {}
        session[:candidacy_vote_form] = session[:candidacy_vote_form].merge(@vote_form.attributes_with_values.except(:candidacy, :signer))
      end

      def candidacy_type
        @candidacy_type ||= current_candidacy&.scoped_type&.type
      end

      def sms_step?
        current_candidacy.validate_sms_code_on_votes?
      end

      def fill_personal_data_step?
        true
      end

      def authorize_wizard_step
        enforce_permission_to :sign_candidacy, :candidacy, candidacy: current_candidacy, signature_has_steps: true
      end

      def set_wizard_steps
        @wizard_steps = [:finish]
        @wizard_steps.unshift(:sms_phone_number, :sms_code) if sms_step?
        @wizard_steps.unshift(:fill_personal_data) if fill_personal_data_step?
      end

      def extra_data_legal_information
        @extra_data_legal_information ||= candidacy_type.extra_fields_legal_information
      end

      def session_vote_form
        attributes = session[:candidacy_vote_form].merge(candidacy: current_candidacy, signer: current_user)

        @vote_form = form(Decidim::SignatureCollection::VoteForm).from_params(attributes)
      end

      def check_session_personal_data
        return if session[:candidacy_vote_form].present? && session_vote_form&.valid?

        flash[:alert] = I18n.t("create.error", scope: "decidim.signature_collection.candidacy_votes")
        redirect_to fill_personal_data_path
      end

      def clear_session_sms_code
        session[:candidacy_sms_code] = {}
      end

      def store_session_sms_code(metadata)
        session[:candidacy_sms_code] = metadata
      end

      def session_sms_code
        session[:candidacy_sms_code]
      end
    end
  end
end
