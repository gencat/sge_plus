# frozen_string_literal: true

module Decidim
  module Candidacies
    module ContentBlocks
      class RegistryManager
        def self.register!
          Decidim.content_blocks.register(:homepage, :highlighted_candidacies) do |content_block|
            content_block.cell = "decidim/candidacies/content_blocks/highlighted_candidacies"
            content_block.public_name_key = "decidim.candidacies.content_blocks.highlighted_candidacies.name"
            content_block.settings_form_cell = "decidim/candidacies/content_blocks/highlighted_candidacies_settings_form"

            content_block.settings do |settings|
              settings.attribute :max_results, type: :integer, default: 4
              settings.attribute :order, type: :string, default: "default"
            end
          end
        end
      end
    end
  end
end
