# frozen_string_literal: true

class AddSettingsToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :child_scope_threshold_enabled, :boolean, null: false, default: false
    add_column :decidim_signature_collection_candidacies_types, :only_global_scope_enabled, :boolean, null: false, default: false
  end
end
