# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171023075942)
class CreateCandidacyExtraData < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_signature_collection_candidacies_extra_data do |t|
      t.references :decidim_candidacy, null: false, index: { name: "idx_signaturecollect_candidacies_on_candidacy_id" }
      t.integer :data_type, null: false, default: 0
      t.jsonb :data, null: false
    end
  end
end
