# frozen_string_literal: true

class RemoveRequiresValidationFromDecidimCandidaciesType < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_signature_collection_candidacies_types,
                  :requires_validation, :boolean, null: false, default: true
  end
end
