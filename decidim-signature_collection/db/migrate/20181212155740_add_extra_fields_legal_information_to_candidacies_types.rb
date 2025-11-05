# frozen_string_literal: true

class AddExtraFieldsLegalInformationToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :extra_fields_legal_information, :jsonb
  end
end
