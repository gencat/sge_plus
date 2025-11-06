# frozen_string_literal: true
# This migration comes from decidim_signature_collection (originally 20251023072530)
class AddCreationEnabledToDecidimCandidaciesSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_settings, :creation_enabled, :boolean, default: true
  end
end
