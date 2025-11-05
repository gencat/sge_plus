# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20181211112538)
class AddReferenceToCandidacies < ActiveRecord::Migration[5.2]
  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies

    belongs_to :organization,
               foreign_key: "decidim_organization_id",
               class_name: "Decidim::Organization"

    include Decidim::Participable
    include Decidim::HasReference
  end

  def change
    add_column :decidim_signature_collection_candidacies, :reference, :string

    reversible do |dir|
      dir.up do
        Candidacy.find_each(&:touch)
      end
    end
  end
end
