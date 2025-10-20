# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A command with all the business logic that creates a new membership
    # request for the committee of an candidacy.
    class SpawnCommitteeRequest < Decidim::Command
      delegate :current_user, to: :form
      # Public: Initializes the command.
      #
      # form - Decidim::SignatureCollection::Candidacy::CommitteeMemberForm
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form was not valid and we could not proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        request = create_request

        if request.persisted?
          notify_author
          broadcast(:ok, request)
        else
          broadcast(:invalid, request)
        end
      end

      private

      attr_reader :form

      def create_request
        request = CandidaciesCommitteeMember.new(
          decidim_signature_collection_candidacy_id: form.candidacy_id,
          decidim_users_id: form.user_id,
          state: form.state
        )
        return request unless request.valid?

        request.save
        request
      end

      def notify_author
        return if candidacy.author == current_user

        Decidim::EventsManager.publish(
          event: "decidim.events.signature_collection.spawn_committee_request",
          event_class: Decidim::SignatureCollection::SpawnCommitteeRequestEvent,
          resource: candidacy,
          affected_users: [candidacy.author],
          force_send: true,
          extra: { applicant: { id: current_user&.id } }
        )
      end

      def candidacy
        @candidacy ||= Decidim::SignatureCollection::Candidacy.find(form.candidacy_id)
      end
    end
  end
end
