# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Custom helpers, scoped to the candidacies engine.
    #
    module ApplicationHelper
      include Decidim::CheckBoxesTreeHelper
      include Decidim::DateRangeHelper
      include CandidaciesHelper

      def filter_states_values
        TreeNode.new(
          TreePoint.new("", t("decidim.signature_collection.application_helper.filter_state_values.all")),
          [
            TreePoint.new("open", t("decidim.signature_collection.application_helper.filter_state_values.open")),
            TreeNode.new(
              TreePoint.new("closed", t("decidim.signature_collection.application_helper.filter_state_values.closed")),
              [
                TreePoint.new("accepted", t("decidim.signature_collection.application_helper.filter_state_values.accepted")),
                TreePoint.new("rejected", t("decidim.signature_collection.application_helper.filter_state_values.rejected"))
              ]
            ),
            TreePoint.new("answered", t("decidim.signature_collection.application_helper.filter_state_values.answered"))
          ]
        )
      end

      def filter_types_values
        types_values = Decidim::SignatureCollection::CandidaciesType.where(organization: current_organization, published: true).map do |type|
          TreeNode.new(
            TreePoint.new(type.id.to_s, type.title[I18n.locale.to_s])
          )
        end

        TreeNode.new(
          TreePoint.new("", t("decidim.signature_collection.application_helper.filter_type_values.all")),
          types_values
        )
      end

      def component_name
        (defined?(current_component) && translated_attribute(current_component&.name).presence) || t("decidim.admin.models.candidacies.fields.title")
      end
    end
  end
end
