# frozen_string_literal: true

class RemoveScopeFromDecidimCandidaciesVotes < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_signature_collection_candidacies_votes, :scope, :integer
  end
end
