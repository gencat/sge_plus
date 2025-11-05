# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Data store the committee members for the candidacy
    class CandidaciesCommitteeMember < ApplicationRecord
      belongs_to :candidacy,
                 foreign_key: "decidim_signature_collection_candidacy_id",
                 class_name: "Decidim::SignatureCollection::Candidacy",
                 inverse_of: :committee_members

      belongs_to :user,
                 foreign_key: "decidim_users_id",
                 class_name: "Decidim::User"

      enum state: [:requested, :rejected, :accepted]

      validates :state, presence: true
      validates :user, uniqueness: { scope: :candidacy }

      scope :approved, -> { where(state: :accepted) }
      scope :non_deleted, -> { includes(:user).where(decidim_users: { deleted_at: nil }) }
      scope :excluding_author, -> { joins(:candidacy).where.not("decidim_users_id = decidim_author_id") }
    end
  end
end
