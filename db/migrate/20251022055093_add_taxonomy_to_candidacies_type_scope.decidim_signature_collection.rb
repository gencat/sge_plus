# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20241127104718)
class AddTaxonomyToCandidaciesTypeScope < ActiveRecord::Migration[7.0]
  def change
    add_reference :decidim_signature_collection_candidacies_type_scopes, :decidim_taxonomy, index: { name: "index_candidacies_type_scopes_on_taxonomy_id" },
                                                                                            foreign_key: { to_table: :decidim_taxonomies }, null: true
  end
end
