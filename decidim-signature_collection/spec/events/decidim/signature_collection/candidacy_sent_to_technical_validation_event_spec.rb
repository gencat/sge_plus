# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::CandidacySentToTechnicalValidationEvent do
  include_context "when a simple event"

  let(:resource) { create(:candidacy) }
  let(:participatory_space) { resource }
  let(:event_name) { "decidim.events.signature_collection.candidacy_sent_to_technical_validation" }
  let(:admin_candidacy_path) { "/admin/candidacies/#{resource.slug}/edit" }
  let(:admin_candidacy_url) { "http://#{organization.host}:#{Capybara.server_port}#{admin_candidacy_path}" }
  let(:email_subject) { "Candidacy \"#{resource_title}\" was sent to technical validation." }
  let(:email_outro) { "You have received this notification because you are an admin of the platform." }
  let(:email_intro) { %(The candidacy "#{resource_title}" has been sent to technical validation. Check it out at <a href="#{admin_candidacy_url}">the admin panel</a>) }
  let(:notification_title) { %(The candidacy "#{resource_title}" has been sent to technical validation. Check it out at <a href="#{resource_path}">the admin panel</a>) }

  context "with email translations", skip: "The email translations of this event are missing" do
    it_behaves_like "a simple event"
    it_behaves_like "a simple event email"
  end

  it_behaves_like "a simple event notification"
end
