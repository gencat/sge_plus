# frozen_string_literal: true

module Decidim
  module Candidacies
    class CandidacyDropdownMetadataCell < Decidim::ParticipatorySpaceDropdownMetadataCell
      include CandidacysHelper
      include Decidim::ComponentPathHelper
      include ActiveLinkTo

      def decidim_candidacies
        Decidim::Candidacies::Engine.routes.url_helpers
      end

      private

      def nav_items_method = :candidacy_nav_items
    end
  end
end
