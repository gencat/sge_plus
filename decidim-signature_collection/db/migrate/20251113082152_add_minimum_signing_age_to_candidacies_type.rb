# frozen_string_literal: true

class AddMinimumSigningAgeToCandidaciesType < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_types, :minimum_signing_age, :integer
  end
end
