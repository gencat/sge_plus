# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20200528151456)
class RemoveUserGroupsFromCandidacyVotes < ActiveRecord::Migration[5.2]
  def change
    remove_column :decidim_signature_collection_candidacies_votes, :decidim_user_group_id
  end
end
