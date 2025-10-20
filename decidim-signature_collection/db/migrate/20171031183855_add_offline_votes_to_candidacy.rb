# frozen_string_literal: true

class AddOfflineVotesToCandidacy < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies,
               :offline_votes, :integer
  end
end
