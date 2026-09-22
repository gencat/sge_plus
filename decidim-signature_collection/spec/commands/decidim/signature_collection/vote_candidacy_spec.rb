# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe VoteCandidacy, skip: "Awaiting review" do
      let(:form_klass) { VoteForm }
      let(:organization) { create(:organization) }
      let(:candidacy) { create(:candidacy, organization:) }

      let(:current_user) { create(:user, organization: candidacy.organization) }
      let(:form) do
        form_klass
          .from_params(
            form_params
          ).with_context(current_organization: organization)
      end

      let(:form_params) do
        {
          candidacy:
        }
      end

      let(:personal_data_params) do
        {
          name: ::Faker::Name.name,
          first_surname: ::Faker::Name.last_name,
          second_surname: ::Faker::Name.last_name,
          document_type: 1,
          document_number: ::Faker::IdNumber.spanish_citizen_number,
          date_of_birth: ::Faker::Date.birthday(min_age: 18, max_age: 40),
          postal_code: ::Faker::Address.zip_code
        }
      end

      describe "User votes candidacy" do
        let(:command) { described_class.new(form) }

        it "broadcasts ok" do
          expect { command.call }.to broadcast :ok
        end

        it "creates a vote" do
          expect do
            command.call
          end.to change(CandidaciesVote, :count).by(1)
        end

        it "increases the vote counter by one" do
          expect do
            command.call
            candidacy.reload
          end.to change(candidacy, :online_votes_count).by(1)
        end

        it "notifies the creation" do
          follower = create(:user, organization: candidacy.organization)
          create(:follow, followable: candidacy.author, user: follower)

          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.signature_collection.candidacy_endorsed",
              event_class: Decidim::SignatureCollection::EndorseCandidacyEvent,
              resource: candidacy,
              followers: [follower]
            )

          command.call
        end

        it "sends notification with email" do
          follower = create(:user, organization: candidacy.organization)
          create(:follow, followable: candidacy.author, user: follower)

          expect do
            perform_enqueued_jobs { command.call }
          end.to change(emails, :count).by(2)

          expect(last_email_body).to include("has endorsed the following candidacy")
        end

        context "when a new milestone is completed" do
          let(:candidacy) do
            create(:candidacy,
                   organization:,
                   scoped_type: create(
                     :candidacies_type_scope,
                     supports_required: 4,
                     type: create(:candidacies_type, organization:)
                   ))
          end

          let!(:follower) { create(:user, organization: candidacy.organization) }
          let!(:follow) { create(:follow, followable: candidacy, user: follower) }

          before do
            create(:candidacy_user_vote, candidacy:)
            create(:candidacy_user_vote, candidacy:)
          end

          it "notifies the followers" do
            expect(Decidim::EventsManager).to receive(:publish)
              .with(kind_of(Hash))

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.milestone_completed",
                event_class: Decidim::SignatureCollection::MilestoneCompletedEvent,
                resource: candidacy,
                affected_users: [candidacy.author],
                followers: [follower],
                extra: { percentage: 75 }
              )

            command.call
          end

          it "sends notification with email" do
            expect do
              perform_enqueued_jobs { command.call }
            end.to change(emails, :count).by(3)

            expect(last_email_body).to include("has achieved the 75% of signatures")
          end
        end

        context "when support threshold is reached" do
          let!(:admin) { create(:user, :admin, :confirmed, organization:) }
          let(:candidacy) do
            create(:candidacy,
                   organization:,
                   scoped_type: create(
                     :candidacies_type_scope,
                     supports_required: 4,
                     type: create(:candidacies_type, organization:)
                   ))
          end

          before do
            create(:candidacy_user_vote, candidacy:)
            create(:candidacy_user_vote, candidacy:)
            create(:candidacy_user_vote, candidacy:)
          end

          it "notifies the admins" do
            expect(Decidim::EventsManager).to receive(:publish)
              .with(kind_of(Hash)).twice

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.support_threshold_reached",
                event_class: Decidim::SignatureCollection::Admin::SupportThresholdReachedEvent,
                resource: candidacy,
                followers: [admin]
              )

            command.call
          end

          it "sends notification with email" do
            expect do
              perform_enqueued_jobs { command.call }
            end.to change(emails, :count).by(3)

            expect(last_email_body).to include("has reached the signatures threshold")
          end

          context "when more votes are added" do
            before do
              create(:candidacy_user_vote, candidacy:)
            end

            it "does not notifies the admins" do
              expect(Decidim::EventsManager).to receive(:publish)
                .with(kind_of(Hash)).once

              expect(Decidim::EventsManager)
                .not_to receive(:publish)
                .with(
                  event: "decidim.events.support_threshold_reached",
                  event_class: Decidim::SignatureCollection::Admin::SupportThresholdReachedEvent,
                  resource: candidacy,
                  followers: [admin]
                )

              expect do
                perform_enqueued_jobs { command.call }
              end.to change(emails, :count).by(1)
            end
          end
        end
      end
    end
  end
end
