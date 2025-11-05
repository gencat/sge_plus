# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::EndorseCandidacyEvent do
  subject do
    described_class.new(resource:, event_name:, user:, extra: {})
  end

  include_context "when a simple event"

  include Decidim::TranslationsHelper

  let(:organization) { resource.organization }
  let(:resource) { create(:candidacy) }
  let(:candidacy_author) { resource.author }
  let(:event_name) { "decidim.events.signature_collection.candidacy_endorsed" }
  let(:user) { create(:user, organization:) }
  let(:resource_path) { resource_locator(resource).path }
  let(:email_subject) { "Candidacy endorsed by @#{candidacy_author.nickname}" }
  let(:email_intro) { "#{candidacy_author.name} @#{candidacy_author.nickname}, who you are following, has endorsed the following candidacy, maybe you want to contribute to the conversation:" }
  let(:email_outro) { "You have received this notification because you are following @#{candidacy_author.nickname}. You can stop receiving notifications following the previous link." }
  let(:notification_title) { <<-EOTITLE.squish }
    The <a href="#{resource_path}">#{resource_title}</a> candidacy was endorsed by
    <a href="/profiles/#{candidacy_author.nickname}">#{candidacy_author.name} @#{candidacy_author.nickname}</a>.
  EOTITLE

  describe "types" do
    subject { described_class }

    it "supports notifications" do
      expect(subject.types).to include :notification
    end

    it "supports emails" do
      expect(subject.types).to include :email
    end
  end

  it_behaves_like "a simple event email"
  it_behaves_like "a simple event notification"
end
