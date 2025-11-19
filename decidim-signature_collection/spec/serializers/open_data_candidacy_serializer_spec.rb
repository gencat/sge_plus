# frozen_string_literal: true

require "spec_helper"

module Decidim::SignatureCollection
  describe OpenDataCandidacySerializer do
    subject { described_class.new(candidacy) }

    let(:candidacy) { create(:candidacy, :with_area) }
    let(:serialized) { subject.serialize }

    describe "#serialize" do
      it "includes the reference" do
        expect(serialized).to include(reference: candidacy.reference)
      end

      it "includes the title" do
        expect(serialized).to include(title: candidacy.title)
      end

      it "includes the url" do
        expect(serialized).to include(url: "http://#{candidacy.organization.host}:#{Capybara.server_port}/candidacies/i-#{candidacy.id}")
      end

      it "includes the description" do
        expect(serialized).to include(description: candidacy.description)
      end

      it "includes the state" do
        expect(serialized).to include(state: candidacy.state)
      end

      it "includes the created_at timestamp" do
        expect(serialized).to include(created_at: candidacy.created_at)
      end

      it "includes the updated_at timestamp" do
        expect(serialized).to include(updated_at: candidacy.updated_at)
      end

      it "includes the published_at timestamp" do
        expect(serialized).to include(published_at: candidacy.published_at)
      end

      context "when candidacy has no custom signature dates" do
        before do
          candidacy.update!(signature_start_date: nil, signature_end_date: nil)
        end

        it "includes the signature_start_date from candidacy type" do
          expect(serialized).to include(signature_start_date: candidacy.type.signature_period_start.to_date)
        end

        it "includes the signature_end_date from candidacy type" do
          expect(serialized).to include(signature_end_date: candidacy.type.signature_period_end.to_date)
        end
      end

      context "when candidacy has custom signature dates" do
        let(:custom_start_date) { 1.month.ago.to_date }
        let(:custom_end_date) { 1.month.from_now.to_date }

        before do
          candidacy.update!(signature_start_date: custom_start_date, signature_end_date: custom_end_date)
        end

        it "includes the candidacy signature_start_date" do
          expect(serialized).to include(signature_start_date: custom_start_date)
        end

        it "includes the candidacy signature_end_date" do
          expect(serialized).to include(signature_end_date: custom_end_date)
        end

        it "does not include the type signature period dates" do
          expect(serialized).not_to include(signature_start_date: candidacy.type.signature_period_start.to_date)
          expect(serialized).not_to include(signature_end_date: candidacy.type.signature_period_end.to_date)
        end
      end

      it "includes the signature_type" do
        expect(serialized).to include(signature_type: candidacy.signature_type)
      end

      it "includes the number of signatures (supports)" do
        expect(serialized).to include(signatures: candidacy.supports_count)
      end

      it "includes the answer" do
        expect(serialized).to include(answer: candidacy.answer)
      end

      it "includes the answered_at" do
        expect(serialized).to include(answered_at: candidacy.answered_at)
      end

      it "includes the answer_url" do
        expect(serialized).to include(answer_url: candidacy.answer_url)
      end

      it "includes the first_progress_notification_at timestamp" do
        expect(serialized).to include(first_progress_notification_at: candidacy.first_progress_notification_at)
      end

      it "includes the second_progress_notification_at timestamp" do
        expect(serialized).to include(second_progress_notification_at: candidacy.second_progress_notification_at)
      end

      it "includes the online_votes" do
        expect(serialized).to include(online_votes: candidacy.online_votes)
      end

      it "includes the offline_votes" do
        expect(serialized).to include(offline_votes: candidacy.offline_votes)
      end

      it "includes the comments_count" do
        expect(serialized).to include(comments_count: candidacy.comments_count)
      end

      it "includes the follows_count" do
        expect(serialized).to include(follows_count: candidacy.follows_count)
      end

      it "includes the scope id" do
        expect(serialized[:scope]).to include(id: candidacy.scope.id)
      end

      it "includes the scope name" do
        expect(serialized[:scope]).to include(name: candidacy.scope.name)
      end

      it "includes the type id" do
        expect(serialized[:type]).to include(id: candidacy.type.id)
      end

      it "includes the type title" do
        expect(serialized[:type]).to include(title: candidacy.type.title)
      end

      it "includes the authors' ids" do
        expect(serialized[:authors]).to include(id: candidacy.author_users.map(&:id))
      end

      it "includes the authors' names" do
        expect(serialized[:authors]).to include(name: candidacy.author_users.map(&:name))
      end

      it "includes the area id" do
        expect(serialized[:area]).to include(id: candidacy.area.id)
      end

      it "includes the area name" do
        expect(serialized[:area]).to include(name: candidacy.area.name)
      end
    end
  end
end
