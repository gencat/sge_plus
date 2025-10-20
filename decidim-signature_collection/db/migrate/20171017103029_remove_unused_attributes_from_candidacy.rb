# frozen_string_literal: true

class RemoveUnusedAttributesFromCandidacy < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_signature_collection_candidacies, :banner_image, :string
    remove_column :decidim_signature_collection_candidacies, :decidim_scope_id, :integer, index: { name: "idx_signaturecollect_candidacies_on_decidim_scope_id" }
    remove_column :decidim_signature_collection_candidacies, :type_id, :integer, index: { name: "idx_signaturecollect_candidacies_on_type_id" }
  end
end
