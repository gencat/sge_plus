# frozen_string_literal: true

class AddEncryptedMetadataToDecidimCandidaciesVotes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :encrypted_metadata, :text
  end
end
