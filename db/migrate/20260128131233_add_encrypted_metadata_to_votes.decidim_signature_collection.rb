# This migration comes from decidim_signature_collection (originally 20260128131153)
class AddEncryptedMetadataToVotes < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :encrypted_metadata, :text
  end
end
