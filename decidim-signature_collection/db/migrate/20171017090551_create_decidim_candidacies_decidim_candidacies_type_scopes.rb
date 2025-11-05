# frozen_string_literal: true

class CreateDecidimCandidaciesDecidimCandidaciesTypeScopes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_signature_collection_candidacies_type_scopes do |t|
      t.references :decidim_signature_collection_candidacies_type, index: { name: "idx_scoped_candidacy_type_type" }
      t.references :decidim_scopes, index: { name: "idx_scoped_candidacy_type_scope" }
      t.integer :supports_required, null: false

      t.timestamps
    end
  end
end
