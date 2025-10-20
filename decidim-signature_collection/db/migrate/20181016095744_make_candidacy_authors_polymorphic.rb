# frozen_string_literal: true

class MakeCandidacyAuthorsPolymorphic < ActiveRecord::Migration[5.2]
  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies
  end

  def change
    remove_index :decidim_signature_collection_candidacies, :decidim_author_id

    add_column :decidim_signature_collection_candidacies, :decidim_author_type, :string

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE decidim_signature_collection_candidacies
          SET decidim_author_type = 'Decidim::UserBaseEntity'
        SQL
      end
    end

    add_index :decidim_signature_collection_candidacies,
              [:decidim_author_id, :decidim_author_type],
              name: "index_decidim_candidacies_on_decidim_author"

    change_column_null :decidim_signature_collection_candidacies, :decidim_author_id, false
    change_column_null :decidim_signature_collection_candidacies, :decidim_author_type, false

    Candidacy.reset_column_information
  end
end
