# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20260908094452)
class AddMissingUniqueIndexesForCandidacies < ActiveRecord::Migration[7.0]
  def change
    add_index :decidim_signature_collection_candidacies_committee_members,
              [:decidim_signature_collection_candidacy_id, :decidim_users_id],
              unique: true,
              name: "idx_uniq_committee_members_candidacy_user"

    add_index :decidim_signature_collection_candidacies_type_scopes,
              [:decidim_signature_collection_candidacies_type_id, :decidim_scopes_id],
              unique: true,
              name: "idx_uniq_type_scopes_type_scope"

    add_index :decidim_signature_collection_candidacies_votes,
              [:decidim_signature_collection_candidacy_id, :hash_id],
              unique: true,
              name: "idx_uniq_votes_candidacy_hash"
  end
end
