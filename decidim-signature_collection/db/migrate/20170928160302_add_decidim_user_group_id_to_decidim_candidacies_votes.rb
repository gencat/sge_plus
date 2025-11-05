# frozen_string_literal: true

class AddDecidimUserGroupIdToDecidimCandidaciesVotes < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies_votes,
               :decidim_user_group_id, :integer, index: { name: "idx_signaturecollect_candidacy_votes_on_user_group_id" }
  end
end
