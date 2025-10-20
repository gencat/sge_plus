# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20200514085422)
class AddAreaToCandidacies < ActiveRecord::Migration[5.2]
  def change
    add_reference :decidim_signature_collection_candidacies, :decidim_area, index: { name: "idx_signaturecollect_candidacies_on_decidim_area_id" }
  end
end
