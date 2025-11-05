# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181220134322)
class AddEncryptedMetadataToDecidimCandidaciesVotes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :encrypted_metadata, :text
  end
end
