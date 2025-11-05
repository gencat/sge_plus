# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171013090432)
class AddCandidacySupportsCountToCandidacy < ActiveRecord::Migration[5.1]
  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies
  end

  def change
    add_column :decidim_signature_collection_candidacies, :candidacy_supports_count, :integer, null: false, default: 0

    reversible do |change|
      change.up do
        Candidacy.find_each do |candidacy|
          candidacy.candidacy_supports_count = candidacy.votes.supports.count
          candidacy.save
        end
      end
    end
  end
end
