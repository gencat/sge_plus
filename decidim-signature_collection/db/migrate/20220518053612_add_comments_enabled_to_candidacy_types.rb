# frozen_string_literal: true

class AddCommentsEnabledToCandidacyTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_signature_collection_candidacies_types, :comments_enabled, :boolean, null: false, default: true
  end
end
