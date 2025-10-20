# frozen_string_literal: true

class CreateDecidimCandidaciesTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_signature_collection_candidacies_types do |t|
      t.jsonb :title, null: false
      t.jsonb :description, null: false
      t.integer :supports_required, null: false

      t.integer :decidim_organization_id,
                foreign_key: true,
                index: {
                  name: "index_decidim_candidacy_types_on_decidim_organization_id"
                }

      t.timestamps
    end
  end
end
