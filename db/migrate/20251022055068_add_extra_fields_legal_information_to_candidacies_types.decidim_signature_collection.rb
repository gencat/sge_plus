# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181212155740)
class AddExtraFieldsLegalInformationToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :extra_fields_legal_information, :jsonb
  end
end
