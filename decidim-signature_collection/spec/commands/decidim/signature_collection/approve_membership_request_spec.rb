# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe ApproveMembershipRequest do
      let(:organization) { create(:organization) }
      let!(:candidacy) { create(:candidacy, :created, organization:) }
      let(:author) { candidacy.author }
      let(:membership_request) { create(:candidacies_committee_member, candidacy:, state: "requested") }
      let(:command) { described_class.new(membership_request) }

      context "when everything is ok" do
        it "broadcasts ok" do
          expect { command.call }.to broadcast :ok
        end

        it "notifies author" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.signature_collection.approve_membership_request",
              event_class: Decidim::SignatureCollection::ApproveMembershipRequestEvent,
              resource: candidacy,
              affected_users: [membership_request.user],
              force_send: true,
              extra: { author: { id: candidacy.author.id } }
            )

          command.call
        end

        it "approves membership requests" do
          expect do
            command.call
          end.to change(membership_request, :state).from("requested").to("accepted")
        end
      end
    end
  end
end
