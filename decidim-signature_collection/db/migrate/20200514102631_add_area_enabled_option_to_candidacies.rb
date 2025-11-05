# frozen_string_literal: true

class AddAreaEnabledOptionToCandidacies < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :area_enabled, :boolean, null: false, default: false
  end
end
