# frozen_string_literal: true

module Decidim
  module Candidacies
    class CandidacysTypeSignatureTypesController < Decidim::Candidacies::ApplicationController
      helper_method :allowed_signature_types_for_candidacies

      # GET /candidacy_type_signature_types/search
      def search
        enforce_permission_to :search, :candidacy_type_signature_types
        render layout: false
      end

      private

      def allowed_signature_types_for_candidacies
        @allowed_signature_types_for_candidacies ||= CandidacysType.where(organization: current_organization).find(params[:type_id]).allowed_signature_types_for_candidacies
      end
    end
  end
end
