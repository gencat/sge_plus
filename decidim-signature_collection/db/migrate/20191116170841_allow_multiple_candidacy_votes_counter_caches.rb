# frozen_string_literal: true

class AllowMultipleCandidacyVotesCounterCaches < ActiveRecord::Migration[5.2]
  class CandidacyVote < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_votes
  end

  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies
    has_many :votes, foreign_key: "decidim_candidacy_id", class_name: "CandidacyVote"
  end

  def change
    add_column :decidim_signature_collection_candidacies, :online_votes, :jsonb, default: {}

    Candidacy.reset_column_information

    Candidacy.find_each do |candidacy|
      online_votes = candidacy.votes.group(:decidim_scope_id).count.each_with_object({}) do |(scope_id, count), counters|
        counters[scope_id || "global"] = count
        counters["total"] = count
      end

      # rubocop:disable Rails/SkipsModelValidations
      candidacy.update_column("online_votes", online_votes)
      # rubocop:enable Rails/SkipsModelValidations
    end

    remove_column :decidim_signature_collection_candidacies, :candidacy_supports_count
    remove_column :decidim_signature_collection_candidacies, :candidacy_votes_count
  end
end
