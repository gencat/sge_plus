# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20220518053612)
class AddCommentsEnabledToCandidacyTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_signature_collection_candidacies_types, :comments_enabled, :boolean, null: false, default: true
  end
end
