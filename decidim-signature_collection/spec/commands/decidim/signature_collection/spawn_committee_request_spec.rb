# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe SpawnCommitteeRequest do
      let(:candidacy) { create(:candidacy, :created) }
      let(:current_user) { create(:user, organization: candidacy.organization) }
      let(:state) { "requested" }
      let(:form) do
        Decidim::SignatureCollection::CommitteeMemberForm
          .from_params(candidacy_id: candidacy.id, user_id: current_user.id, state:)
          .with_context(
            current_organization: candidacy.organization,
            current_user:
          )
      end
      let(:command) { described_class.new(form) }

      context "when duplicated request" do
        let!(:committee_request) { create(:candidacies_committee_member, user: current_user, candidacy:) }

        it "broadcasts invalid" do
          expect { command.call }.to broadcast :invalid
        end
      end

      context "when everything is ok" do
        it "broadcasts ok" do
          expect { command.call }.to broadcast :ok
        end

        it "notifies author" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.signature_collection.spawn_committee_request",
              event_class: Decidim::SignatureCollection::SpawnCommitteeRequestEvent,
              resource: candidacy,
              affected_users: [candidacy.author],
              force_send: true,
              extra: { applicant: { id: current_user.id } }
            )

          command.call
        end

        it "Creates a committee membership request" do
          expect do
            command.call
          end.to change(CandidaciesCommitteeMember, :count)
        end

        it "Request state is requested" do
          command.call
          request = CandidaciesCommitteeMember.last
          expect(request).to be_requested
        end
      end
    end
  end
end
