# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A form object used to collect the data for a new candidacy committee
    # member.
    class CommitteeMemberForm < Form
      mimic :candidacies_committee_member

      attribute :candidacy_id, Integer
      attribute :user_id, Integer
      attribute :state, String

      validates :candidacy_id, presence: true
      validates :user_id, presence: true
      validates :state, inclusion: { in: %w(requested rejected accepted) }, unless: :user_is_author?
      validates :state, inclusion: { in: %w(rejected accepted) }, if: :user_is_author?

      def user_is_author?
        candidacy&.decidim_author_id == user_id
      end

      private

      def candidacy
        @candidacy ||= Decidim::SignatureCollection::Candidacy.find_by(id: candidacy_id)
      end
    end
  end
end
