# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Helper functions for candidacies views
    module CandidaciesHelper
      # Items to display in the navigation of an candidacy
      def candidacy_nav_items(participatory_space)
        components = participatory_space.components.published.or(Decidim::Component.where(id: try(:current_component)))

        components.map do |component|
          {
            name: decidim_escape_translated(component.name),
            url: main_component_path(component),
            active: is_active_link?(main_component_path(component), :inclusive)
          }
        end
      end

      private

      # i18n-tasks-use t('decidim.signature_collection.candidacies.filters.state')
      # i18n-tasks-use t('decidim.signature_collection.candidacies.filters.scope')
      # i18n-tasks-use t('decidim.signature_collection.candidacies.filters.type')
      # i18n-tasks-use t('decidim.signature_collection.candidacies.filters.area')
      # i18n-tasks-use t('decidim.signature_collection.candidacies.filters.author')
      def filter_sections
        sections = [
          { method: :with_any_state, collection: filter_states_values, label: t("decidim.signature_collection.candidacies.filters.state"), id: "state" },
          { method: :with_any_scope, collection: filter_global_scopes_values, label: t("decidim.signature_collection.candidacies.filters.scope"), id: "scope" }
        ]
        unless single_candidacy_type?
          sections.append(method: :with_any_type, collection: filter_types_values, label: t("decidim.signature_collection.candidacies.filters.type"),
                          id: "type")
        end
        sections.append(method: :with_any_area, collection: filter_areas_values, label: t("decidim.signature_collection.candidacies.filters.area"), id: "area")
        sections.append(method: :author, collection: filter_author_values, label: t("decidim.signature_collection.candidacies.filters.author"), id: "author") if current_user
        sections.reject { |item| item[:collection].blank? }
      end

      def filter_author_values
        [
          ["any", t("any", scope: "decidim.signature_collection.candidacies.filters")],
          ["myself", t("myself", scope: "decidim.signature_collection.candidacies.filters")]
        ]
      end
    end
  end
end
