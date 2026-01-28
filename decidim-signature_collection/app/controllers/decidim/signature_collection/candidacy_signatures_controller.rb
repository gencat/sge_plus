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

        return render_invalid_form if @vote_form.invalid?

        prepare_vote_form_from_params_or_session

        VoteCandidacy.call(@vote_form) do
          on(:ok) do |vote|
            session[:candidacy_vote_form] = {}

            result = ValidSignador::SignatureProcessService.new(
              vote: vote,
              session: session,
              url_helpers: main_app
            ).call

            redirect_to result[:sign_url], allow_other_host: true
          end
          on(:invalid) do |vote|
            Rails.logger.error "Failed creating signature: #{vote.errors.full_messages.join(", ")}" if vote
            flash[:alert] = I18n.t("create.invalid", scope: "decidim.signature_collection.candidacy_votes")
            redirect_to fill_personal_data_path
          end
        end
      end

      private

      attr_reader :wizard_steps

      def fill_personal_data_path
        fill_personal_data_candidacy_signatures_path(current_candidacy)
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

      def render_invalid_form
        flash[:alert] = I18n.t("personal_data.invalid", scope: "decidim.signature_collection.candidacy_votes")
        @form = @vote_form
        render :fill_personal_data
      end

      def prepare_vote_form_from_params_or_session
        params.has_key?(:candidacies_vote) ? build_vote_form(params) : check_session_personal_data
      end
    end
  end
end
