# frozen_string_literal: true

class AddOnlineSignatureEnabledToCandidacyType < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :online_signature_enabled, :boolean, null: false, default: true
  end
end
