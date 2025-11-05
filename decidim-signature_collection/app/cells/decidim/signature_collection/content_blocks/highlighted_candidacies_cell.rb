# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module ContentBlocks
      class HighlightedCandidaciesCell < Decidim::ContentBlocks::HighlightedParticipatorySpacesCell
        BLOCK_ID = "highlighted-candidacies"

        delegate :current_organization, to: :controller

        def highlighted_spaces
          @highlighted_spaces ||= OrganizationPrioritizedCandidacies
                                  .new(current_organization, order)
                                  .query
        end

        def i18n_scope
          "decidim.signature_collection.pages.home.highlighted_candidacies"
        end

        def all_path
          Decidim::SignatureCollection::Engine.routes.url_helpers.candidacies_path
        end

        private

        def max_results
          model.settings.max_results
        end

        def order
          model.settings.order
        end

        def block_id = BLOCK_ID
      end
    end
  end
end
