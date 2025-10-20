# frozen_string_literal: true

class AddTimestampToDecidimCandidaciesVotes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_votes, :timestamp, :string
  end
end
