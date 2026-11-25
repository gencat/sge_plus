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

        # Votes are created unsigned and are not counted until Signador signs them,
        # so this command never completes a milestone nor reaches the threshold.
        context "when the vote would complete a new milestone" do
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
            create_list(:candidacy_user_vote, 2, :signed, candidacy:)
          end

          it "does not change the percentage" do
            expect { command.call }.not_to(change { candidacy.reload.percentage }.from(50))
          end

          it "only notifies the endorsement" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .once
              .with(hash_including(event: "decidim.events.signature_collection.candidacy_endorsed"))

            command.call
          end

          it "does not send any email to the followers of the candidacy" do
            expect do
              perform_enqueued_jobs { command.call }
            end.not_to change(emails, :count)
          end
        end

        context "when the vote would reach the support threshold" do
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
            create_list(:candidacy_user_vote, 3, :signed, candidacy:)
          end

          it "does not change the percentage" do
            expect { command.call }.not_to(change { candidacy.reload.percentage }.from(75))
          end

          it "only notifies the endorsement" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .once
              .with(hash_including(event: "decidim.events.signature_collection.candidacy_endorsed"))

            command.call
          end

          it "does not send any email to the admins" do
            expect do
              perform_enqueued_jobs { command.call }
            end.not_to change(emails, :count)
          end

          context "when the threshold has already been reached" do
            before do
              create(:candidacy_user_vote, :signed, candidacy:)
            end

            it "does not notify the admins" do
              expect(candidacy.reload.percentage).to eq(100)
              expect(Decidim::EventsManager)
                .to receive(:publish)
                .once
                .with(hash_including(event: "decidim.events.signature_collection.candidacy_endorsed"))

              command.call
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
