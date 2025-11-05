# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181224101041)
class AddHashIdToDecidimCandidaciesVotes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :hash_id, :string
  end
end
