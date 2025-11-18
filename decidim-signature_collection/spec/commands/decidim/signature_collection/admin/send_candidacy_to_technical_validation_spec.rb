# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe SendCandidacyToTechnicalValidation do
        subject { described_class.new(candidacy, user) }

        let(:candidacy) { create(:candidacy) }
        let(:organization) { candidacy.organization }
        let(:user) { create(:user, :admin, :confirmed, organization:) }
        let!(:another_admin) { create(:user, :admin, organization:) }

        context "when everything is ok" do
          it "sends the candidacy to technical validation" do
            expect { subject.call }.to change(candidacy, :state).from("open").to("validating")
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(:send_to_technical_validation, candidacy, user)
              .and_call_original

            expect { subject.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.version).to be_present
          end

          it "notifies the admins" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .once
              .ordered
              .with(
                event: "decidim.events.signature_collection.admin.candidacy_sent_to_technical_validation",
                event_class: Decidim::SignatureCollection::Admin::CandidacySentToTechnicalValidationEvent,
                force_send: true,
                resource: candidacy,
                affected_users: a_collection_containing_exactly(another_admin)
              )

            subject.call
          end

          it "sends email notification to admins" do
            expect(Decidim::SignatureCollection::CandidaciesMailer)
              .to receive(:notify_admins_validation)
              .with(candidacy, a_collection_containing_exactly(another_admin))
              .and_call_original

            expect { subject.call }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(5).times
          end
        end
      end
    end
  end
end
