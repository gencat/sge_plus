class RemoveScopeFromCandidaciesVotes < ActiveRecord::Migration[7.0]
  def change
    remove_column :decidim_signature_collection_candidacies_votes, :decidim_scope_id
  end
end
