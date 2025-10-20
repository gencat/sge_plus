# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20170906094044)
# Migration that creates the signature_collection_candidacies table
class CreateDecidimCandidacies < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_signature_collection_candidacies do |t|
      t.jsonb :title, null: false
      t.jsonb :description, null: false

      t.integer :decidim_organization_id,
                foreign_key: true,
                index: {
                  name: "index_decidim_candidacies_on_decidim_organization_id"
                }

      # Text search indexes for candidacies.
      t.index :title, name: "decidim_candidacies_title_search"
      t.index :description, name: "decidim_candidacies_description_search"

      t.references :decidim_author, index: { name: "idx_signaturecollect_candidacies_on_author_id" }
      t.string :banner_image

      # Publicable
      t.datetime :published_at, index: true

      # Scopeable
      t.integer :decidim_scope_id, index: { name: "idx_signaturecollect_candidacies_on_scope_id" }

      t.references :type, index: { name: "idx_signaturecollect_candidacies_on_type_id" }
      t.integer :state, null: false, default: 0
      t.integer :signature_type, null: false, default: 0
      t.date :signature_start_time, null: false
      t.date :signature_end_time, null: false
      t.jsonb :answer
      t.datetime :answered_at, index: { name: "idx_signaturecollect_candidacies_on_answered_at" }
      t.string :answer_url
      t.integer :candidacy_votes_count, null: false, default: 0

      t.timestamps
    end
  end
end
