# frozen_string_literal: true

class RemoveUserGroupsFromCandidacyVotes < ActiveRecord::Migration[5.2]
  def change
    remove_column :decidim_signature_collection_candidacies_votes, :decidim_user_group_id
  end
end
