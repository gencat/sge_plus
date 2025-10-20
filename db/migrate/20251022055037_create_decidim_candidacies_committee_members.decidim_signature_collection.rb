# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20170922152432)
# Migration that creates the decidim_candidacies_committee_members table
class CreateDecidimCandidaciesCommitteeMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_signature_collection_candidacies_committee_members do |t|
      t.references :decidim_signature_collection_candidacy, index: {
        name: "idx_decidim_committee_members_candidacy"
      }
      t.references :decidim_users, index: {
        name: "idx_decidim_committee_members_user"
      }
      t.integer :state, index: { name: "idx_decidim_committee_members_name" }, null: false, default: 0

      t.timestamps
    end
  end
end
