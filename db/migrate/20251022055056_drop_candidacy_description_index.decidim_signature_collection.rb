# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171102094250)
class DropCandidacyDescriptionIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :decidim_signature_collection_candidacies, :description
  end
end
