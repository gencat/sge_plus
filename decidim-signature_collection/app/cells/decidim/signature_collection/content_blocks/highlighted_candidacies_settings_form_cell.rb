# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module ContentBlocks
      class HighlightedCandidaciesSettingsFormCell < Decidim::ViewModel
        alias form model

        def content_block
          options[:content_block]
        end

        def max_results_label
          I18n.t("decidim.signature_collection.admin.content_blocks.highlighted_candidacies.max_results")
        end

        def order_label
          I18n.t("decidim.signature_collection.admin.content_blocks.highlighted_candidacies.order.label")
        end

        def order_select
          [
            [I18n.t("decidim.signature_collection.admin.content_blocks.highlighted_candidacies.order.default"), "default"],
            [I18n.t("decidim.signature_collection.admin.content_blocks.highlighted_candidacies.order.most_recent"), "most_recent"]
          ]
        end
      end
    end
  end
end
