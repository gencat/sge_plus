# frozen_string_literal: true

class AddScopesToCandidaciesVotes < ActiveRecord::Migration[5.2]
  class CandidacyVote < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_votes
    belongs_to :candidacy, foreign_key: "decidim_candidacy_id", class_name: "Candidacy"
  end

  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies
    belongs_to :scoped_type, class_name: "CandidaciesTypeScope"
  end

  class CandidaciesTypeScope < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_type_scopes
  end

  def change
    add_column :decidim_signature_collection_candidacies_votes, :decidim_scope_id, :integer

    CandidacyVote.reset_column_information

    CandidacyVote.includes(candidacy: :scoped_type).find_each do |vote|
      vote.decidim_scope_id = vote.candidacy.scoped_type.decidim_scopes_id
      vote.save!
    end
  end
end
