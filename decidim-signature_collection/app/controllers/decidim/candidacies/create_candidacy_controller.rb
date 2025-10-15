# frozen_string_literal: true

module Decidim
  module Candidacies
    # Controller in charge of managing the create candidacy wizard.
    class CreateCandidacyController < Decidim::Candidacies::ApplicationController
      layout "layouts/decidim/candidacy_creation"

      include Decidim::FormFactory
      include CandidacyHelper
      include TypeSelectorOptions
      include SingleCandidacyType

      helper Decidim::Admin::IconLinkHelper
      helper CandidacyHelper
      helper SignatureTypeOptionsHelper
      helper Decidim::ActionAuthorizationHelper

      helper_method :scopes
      helper_method :areas
      helper_method :current_candidacy
      helper_method :candidacy_type
      helper_method :promotal_committee_required?

      before_action :authenticate_user!
      before_action :ensure_type_exists,
                    only: [:store_candidacy_type, :fill_data, :store_data, :promotal_committee, :finish]
      before_action :ensure_user_can_create_candidacy,
                    only: [:fill_data, :store_data, :promotal_committee, :finish]
      before_action :ensure_candidacy_exists, only: [:promotal_committee, :finish]

      def select_candidacy_type
        @form = form(Decidim::Candidacies::SelectCandidacyTypeForm).from_params(params)

        redirect_to fill_data_create_candidacy_index_path if single_candidacy_type?
      end

      def store_candidacy_type
        @form = form(Decidim::Candidacies::SelectCandidacyTypeForm).from_params(params)

        if @form.valid?
          session[:type_id] = @form.type_id
          redirect_to fill_data_create_candidacy_index_path
        else
          render :select_candidacy_type
        end
      end

      def fill_data
        @form = if session[:candidacy_id].present?
                  form(Decidim::Candidacies::CandidacyForm).from_model(current_candidacy, { candidacy_type: })
                else
                  extras = { type_id: candidacy_type_id, signature_type: candidacy_type.signature_type }
                  form(Decidim::Candidacies::CandidacyForm).from_params(params.merge(extras), { candidacy_type: })
                end
      end

      def store_data
        @form = form(Decidim::Candidacies::CandidacyForm).from_params(params, { candidacy_type: })

        CreateCandidacy.call(@form) do
          on(:ok) do |candidacy|
            session[:candidacy_id] = candidacy.id

            path = promotal_committee_required? ? "promotal_committee" : "finish"

            redirect_to send(:"#{path}_create_candidacy_index_path")
          end

          on(:invalid) do
            render :fill_data
          end
        end
      end

      def promotal_committee
        redirect_to finish_create_candidacy_index_path unless promotal_committee_required?
      end

      def finish
        current_candidacy.presence
        session[:type_id] = nil
        session[:candidacy_id] = nil
      end

      private

      def ensure_user_can_create_candidacy
        enforce_permission_to :create, :candidacy, { candidacy_type: }
      end

      def candidacy_type_id
        @candidacy_type_id ||= fetch_candidacy_type_id
      end

      def fetch_candidacy_type_id
        return current_organization_candidacies_type.first.id if single_candidacy_type?
        return params.dig(:candidacy, :type_id) if params.dig(:candidacy, :type_id).present?
        return current_candidacy&.type&.id if session[:candidacy_id].present?

        session[:type_id]
      end

      def ensure_candidacy_exists
        redirect_to fill_data_create_candidacy_index_path if session[:candidacy_id].blank?
      end

      def ensure_type_exists
        destination_step = single_candidacy_type? ? "fill_data" : "select_candidacy_type"

        return if action_name == destination_step
        return if candidacy_type_id.present? && candidacy_type.present?

        redirect_to send(:"#{destination_step}_create_candidacy_index_path")
      end

      def scopes
        @scopes ||= @form.available_scopes
      end

      def current_candidacy
        @current_candidacy ||= Candidacy.where(organization: current_organization).find_by(id: session[:candidacy_id] || nil)
      end

      def candidacy_type
        @candidacy_type ||= CandidacysType.where(organization: current_organization).find_by(id: candidacy_type_id)
      end

      def promotal_committee_required?
        return false if candidacy_type.blank?
        return false unless candidacy_type.promoting_committee_enabled?

        minimum_committee_members = candidacy_type.minimum_committee_members ||
                                    Decidim::Candidacies.minimum_committee_members
        minimum_committee_members.present? && minimum_committee_members.positive?
      end
    end
  end
end
