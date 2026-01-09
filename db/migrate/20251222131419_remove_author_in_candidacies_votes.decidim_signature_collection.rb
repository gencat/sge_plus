# This migration comes from decidim_signature_collection (originally 20251222131109)
class RemoveAuthorInCandidaciesVotes < ActiveRecord::Migration[7.0]
  def change
    remove_column :decidim_signature_collection_candidacies_votes, :decidim_author_id
  end
end
