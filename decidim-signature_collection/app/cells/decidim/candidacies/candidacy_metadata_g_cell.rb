# frozen_string_literal: true

module Decidim
  module Candidacies
    # This cell renders the assembly metadata for g card
    class CandidacyMetadataGCell < Decidim::CardMetadataCell
      include Cell::ViewModel::Partial
      include Decidim::Candidacies::CandidacyHelper

      alias current_candidacy resource
      alias candidacy resource

      def initialize(*)
        super

        @items.prepend(*candidacy_items)
      end

      private

      def candidacy_items
        [dates_item, progress_bar_item, state_item].compact
      end

      def start_date
        candidacy.signature_start_date
      end

      def end_date
        candidacy.signature_end_date
      end

      def state_item
        return if candidacy.state.blank?

        {
          text: content_tag(
            :span,
            t(candidacy.state, scope: "decidim.candidacies.show.badge_name"),
            class: "label #{metadata_badge_css_class(candidacy.state)} candidacy-status"
          )
        }
      end

      def progress_bar_item
        return if %w(created validating discarded).include?(candidacy.state)

        type_scope = candidacy.votable_candidacy_type_scopes[0]

        {
          cell: "decidim/progress_bar",
          args: [candidacy.supports_count_for(type_scope.scope), {
            total: type_scope.supports_required,
            element_id: "candidacy-#{candidacy.id}-votes-count",
            class: "progress-bar__sm"
          }],
          icon: nil
        }
      end
    end
  end
end
