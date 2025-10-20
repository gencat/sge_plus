# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe UpdateCandidacyAnswer do
        let(:form_klass) { Decidim::SignatureCollection::Admin::CandidacyAnswerForm }

        context "when valid data" do
          it_behaves_like "update an candidacy answer" do
            context "when the user is an admin" do
              let(:current_user) { create(:user, :admin, organization: candidacy.organization) }

              it "notifies the followers" do
                follower = create(:user, organization:)
                create(:follow, followable: candidacy, user: follower)

                expect(Decidim::EventsManager)
                  .to receive(:publish)
                  .with(
                    event: "decidim.events.signature_collection.candidacy_extended",
                    event_class: Decidim::SignatureCollection::ExtendCandidacyEvent,
                    resource: candidacy,
                    followers: [follower]
                  )

                command.call
              end

              context "when the signature end time is not modified" do
                let(:signature_end_date) { candidacy.signature_end_date }

                it "does not notify the followers" do
                  expect(Decidim::EventsManager).not_to receive(:publish)

                  command.call
                end
              end
            end
          end
        end

        context "when validation failure" do
          let(:organization) { create(:organization) }
          let!(:candidacy) { create(:candidacy, organization:) }
          let!(:form) do
            form_klass
              .from_model(candidacy)
              .with_context(current_organization: organization, candidacy:)
          end

          let(:command) { described_class.new(candidacy, form) }

          it "broadcasts invalid" do
            expect(candidacy).to receive(:valid?)
              .at_least(:once)
              .and_return(false)
            expect { command.call }.to broadcast :invalid
          end
        end
      end
    end
  end
end
