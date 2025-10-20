# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20170917072556)
class CreateDecidimCandidaciesVotes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_signature_collection_candidacies_votes do |t|
      t.references :decidim_signature_collection_candidacy, null: false, index: { name: "idx_signaturecollect_candidacies_votes_on_candidacy_id" }
      t.references :decidim_author, null: false, index: { name: "idx_signaturecollect_candidacies_votes_on_author_id" }
      t.integer :scope, null: false, default: 0

      t.timestamps
    end
  end
end
