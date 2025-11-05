# frozen_string_literal: true
class AddCreationEnabledToDecidimCandidaciesSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_settings, :creation_enabled, :boolean, default: true
  end
end
