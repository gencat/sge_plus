# frozen_string_literal: true

class AddElectionsToCandidaciesTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_signature_collection_candidacies_types, :elections, :string, default: "parliament_of_catalonia", null: false
  end
end
