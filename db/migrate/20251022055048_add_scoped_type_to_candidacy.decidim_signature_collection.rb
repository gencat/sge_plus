# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171017094911)
class AddScopedTypeToCandidacy < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies,
               :scoped_type_id, :integer, index: { name: "idx_signaturecollect_candidacies_on_scoped_type_id" }
  end
end
