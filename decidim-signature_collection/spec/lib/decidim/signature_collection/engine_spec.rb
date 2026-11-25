# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::Engine do
  it_behaves_like "clean engine"

  it "loads engine mailer previews" do
    expect(ActionMailer::Preview.all).to include(Decidim::Candidacies::CandidaciesMailerPreview)
  end

  # The events are translated using their name as the scope, so the names that are published need to have translations.
  describe "event translations" do
    event_names = %w(
      decidim.events.signature_collection.admin.candidacy_sent_to_technical_validation
      decidim.events.signature_collection.candidacy_extended
      decidim.events.signature_collection.candidacy_sent_to_technical_validation
    )

    %w(ca en es).each do |locale|
      context "when the locale is #{locale}" do
        let(:translations) { YAML.load_file(described_class.root.join("config/locales/#{locale}.yml"))[locale] }

        event_names.each do |event_name|
          it "has the texts of #{event_name}" do
            expect(translations.dig(*event_name.split(".")).to_h.keys)
              .to match_array(%w(email_intro email_outro email_subject notification_title))
          end
        end
      end
    end
  end

  describe "decidim_signature_collection.authorization_transfer" do
    include_context "authorization transfer"

    let(:component) { create(:post_component, organization:) }
    let(:original_records) do
      {
        candidacies: create_list(:candidacy, 3, organization:, author: original_user)
      }
    end
    let(:transferred_candidacies) { Decidim::SignatureCollection::Candidacy.where(author: target_user).order(:id) }

    it "handles authorization transfer correctly" do
      expect(transferred_candidacies.count).to eq(3)
      expect(transfer.records.count).to eq(3)
      expect(transferred_resources).to eq(transferred_candidacies)
    end
  end
end
