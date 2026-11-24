# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe VoteCandidacy do
      let(:form_klass) { VoteForm }
      let(:organization) { create(:organization) }
      let(:candidacy) { create(:candidacy, organization:) }

      let(:form) do
        form_klass
          .from_params(
            form_params
          ).with_context(current_organization: organization)
      end

      let(:form_params) do
        {
          candidacy:
        }.merge(personal_data_params)
      end

      let(:document_number) do
        number = ::Faker::Number.number(digits: 8)
        "#{number}#{"TRWAGMYFPDXBNJZSQVHLCKE"[number % 23]}"
      end

      let(:personal_data_params) do
        {
          name: ::Faker::Name.name,
          first_surname: ::Faker::Name.last_name,
          second_surname: ::Faker::Name.last_name,
          document_type: 1,
          document_number:,
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

        it "does not count the vote until it is signed" do
          expect do
            command.call
            candidacy.reload
          end.not_to change(candidacy, :online_votes_count)

          expect do
            CandidaciesVote.last.update!(encrypted_xml_doc_signed: "signed")
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
          end.to change(emails, :count).by(1)

          expect(last_email_body).to include("has endorsed the following candidacy")
        end

        context "when a new milestone is completed", skip: "Votes are created unsigned and are not counted, so VoteCandidacy never reaches a milestone" do
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

        context "when support threshold is reached", skip: "Votes are created unsigned and are not counted, so VoteCandidacy never reaches a milestone" do
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

        it "stores encrypted user personal data in vote" do
          command.call
          vote = CandidaciesVote.last
          expect(vote.encrypted_metadata).to be_present

          encryptor = DataEncryptor.new(secret: Rails.application.secret_key_base)
          expect(encryptor.decrypt(vote.encrypted_metadata)).to eq personal_data_params.as_json
        end

        context "when form does not contain personal data" do
          let(:personal_data_params) { {} }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast :invalid
          end
        end

        context "when document number is not valid" do
          let(:document_number) { "12345678A" }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast :invalid
          end
        end

        context "when another signature exists with the same hash_id" do
          before do
            create(:candidacy_user_vote, candidacy:, hash_id: form.hash_id)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast :invalid
          end
        end
      end
    end
  end
end
