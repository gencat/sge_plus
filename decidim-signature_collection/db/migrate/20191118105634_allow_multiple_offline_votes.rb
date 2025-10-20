# frozen_string_literal: true

class AllowMultipleOfflineVotes < ActiveRecord::Migration[5.2]
  class CandidaciesTypeScope < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_type_scopes
  end

  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies
    belongs_to :scoped_type, class_name: "CandidaciesTypeScope"
  end

  def change
    rename_column :decidim_signature_collection_candidacies, :offline_votes, :old_offline_votes
    add_column :decidim_signature_collection_candidacies, :offline_votes, :jsonb, default: {}

    Candidacy.reset_column_information

    Candidacy.includes(:scoped_type).find_each do |candidacy|
      scope_key = candidacy.scoped_type.decidim_scopes_id || "global"

      offline_votes = {
        scope_key => candidacy.old_offline_votes.to_i,
        "total" => candidacy.old_offline_votes.to_i
      }

      # rubocop:disable Rails/SkipsModelValidations
      candidacy.update_column(:offline_votes, offline_votes)
      # rubocop:enable Rails/SkipsModelValidations
    end

    remove_column :decidim_signature_collection_candidacies, :old_offline_votes
  end
end
