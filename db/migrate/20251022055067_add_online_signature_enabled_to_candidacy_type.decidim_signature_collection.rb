# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181212155125)
class AddOnlineSignatureEnabledToCandidacyType < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :online_signature_enabled, :boolean, null: false, default: true
  end
end
