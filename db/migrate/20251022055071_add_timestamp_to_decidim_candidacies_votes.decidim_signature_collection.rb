# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181224100803)
class AddTimestampToDecidimCandidaciesVotes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :timestamp, :string
  end
end
