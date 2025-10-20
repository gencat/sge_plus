# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171023141639)
class OptionalValidationSupport < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies_types,
               :requires_validation, :boolean, null: false, default: true
  end
end
