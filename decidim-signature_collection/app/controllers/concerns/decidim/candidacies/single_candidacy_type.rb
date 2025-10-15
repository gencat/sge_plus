# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Candidacies
    # Common methods for elements that need specific behaviour when there is only one candidacy type.
    module SingleCandidacyType
      extend ActiveSupport::Concern

      included do
        helper_method :single_candidacy_type?

        private

        def current_organization_candidacies_type
          Decidim::CandidacysType.where(organization: current_organization)
        end

        def single_candidacy_type?
          current_organization_candidacies_type.count == 1
        end
      end
    end
  end
end
