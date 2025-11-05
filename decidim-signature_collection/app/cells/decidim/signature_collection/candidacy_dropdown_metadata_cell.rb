# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class CandidacyDropdownMetadataCell < Decidim::ParticipatorySpaceDropdownMetadataCell
      include CandidaciesHelper
      include Decidim::ComponentPathHelper
      include ActiveLinkTo

      def decidim_candidacies
        Decidim::SignatureCollection::Engine.routes.url_helpers
      end

      private

      def nav_items_method = :candidacy_nav_items
    end
  end
end
