# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe AcceptCandidacy do
        subject { described_class.new(candidacy, user) }

        let(:candidacy) { create(:candidacy, :validating) }
        let(:user) { create(:user, :admin, :confirmed, organization: candidacy.organization) }

        context "when the candidacy is already accepted" do
          let(:candidacy) { create(:candidacy, :accepted) }

          it "broadcasts :invalid" do
            expect { subject.call }.to broadcast(:invalid)
          end
        end

        context "when everything is ok" do
          it "accepts the candidacy" do
            expect { subject.call }.to change(candidacy, :state).from("validating").to("accepted")
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(:accept, candidacy, user)
              .and_call_original

            expect { subject.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.version).to be_present
          end
        end
      end
    end
  end
end
