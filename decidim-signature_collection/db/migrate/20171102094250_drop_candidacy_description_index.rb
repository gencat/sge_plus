# frozen_string_literal: true

class DropCandidacyDescriptionIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :decidim_signature_collection_candidacies, :description
  end
end
