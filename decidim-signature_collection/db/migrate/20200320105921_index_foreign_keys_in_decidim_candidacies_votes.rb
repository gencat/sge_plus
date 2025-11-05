# frozen_string_literal: true

class IndexForeignKeysInDecidimCandidaciesVotes < ActiveRecord::Migration[5.2]
  def change
    add_index :decidim_signature_collection_candidacies_votes, :decidim_user_group_id, name: "idx_signaturecollect_candidacies_votes_on_user_group_id"
    add_index :decidim_signature_collection_candidacies_votes, :hash_id, name: "idx_signaturecollect_candidacies_votes_on_hash_id"
  end
end
