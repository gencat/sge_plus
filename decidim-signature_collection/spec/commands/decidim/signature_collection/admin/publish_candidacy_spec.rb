# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe PublishCandidacy, skip: "Awaiting review" do
        subject { described_class.new(candidacy, user) }

        let(:candidacy) { create(:candidacy, :created) }
        let(:user) { create(:user, :admin, :confirmed, organization: candidacy.organization) }

        context "when the candidacy is already published" do
          let(:candidacy) { create(:candidacy) }

          it "broadcasts :invalid" do
            expect { subject.call }.to broadcast(:invalid)
          end
        end

        context "when everything is ok" do
          it "publishes the candidacy" do
            expect { subject.call }.to change(candidacy, :state).from("created").to("open")
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(:publish, candidacy, user, visibility: "all")
              .and_call_original

            expect { subject.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.version).to be_present
          end

          it "increments the author's score" do
            expect { subject.call }.to change { Decidim::Gamification.status_for(candidacy.author, :candidacies).score }.by(1)
          end
        end
      end
    end
  end
end
