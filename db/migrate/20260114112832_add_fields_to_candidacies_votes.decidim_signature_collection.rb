# This migration comes from decidim_signature_collection (originally 20260114112411)
class AddFieldsToCandidaciesVotes < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :encrypted_xml_doc_to_sign, :text
    add_column :decidim_signature_collection_candidacies_votes, :encrypted_xml_doc_signed, :text
    add_column :decidim_signature_collection_candidacies_votes, :filename, :string

    remove_column :decidim_signature_collection_candidacies_votes, :timestamp
    remove_column :decidim_signature_collection_candidacies_votes, :encrypted_metadata
  end
end
