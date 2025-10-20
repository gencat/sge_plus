# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181213184712)
class AddMinCommitteeMembersToCandidacyType < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :minimum_committee_members, :integer, null: true, default: nil
  end
end
