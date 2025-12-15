# This migration comes from decidim_signature_collection (originally 20251212081729)
class AddElectionsToCandidaciesTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_types, :elections, :string, default: "", null: false
  end
end
