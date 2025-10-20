# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20190213184301)
class AddUndoOnlineSignaturesEnabledToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :undo_online_signatures_enabled, :boolean, null: false, default: true
  end
end
