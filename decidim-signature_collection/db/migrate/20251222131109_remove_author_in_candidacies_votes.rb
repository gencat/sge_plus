# frozen_string_literal: true

class RemoveAuthorInCandidaciesVotes < ActiveRecord::Migration[7.0]
  def change
    remove_column :decidim_signature_collection_candidacies_votes, :decidim_author_id
  end
end
