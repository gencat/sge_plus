# This migration comes from decidim_signature_collection (originally 20251113082152)
class AddMinimumSigningAgeToCandidaciesType < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_types, :minimum_signing_age, :integer
  end
end
