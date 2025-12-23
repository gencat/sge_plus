# This migration comes from decidim_signature_collection (originally 20251222131109)
class AllowNullAuthorInCandidaciesVotes < ActiveRecord::Migration[7.0]
  def change
    change_column_null :decidim_signature_collection_candidacies_votes, :decidim_author_id, true
  end
end
