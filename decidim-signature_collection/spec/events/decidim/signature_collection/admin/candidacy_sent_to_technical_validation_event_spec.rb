# frozen_string_literal: true

require "spec_helper"

# to-do
describe Decidim::SignatureCollection::Admin::CandidacySentToTechnicalValidationEvent do
  # include_context "when a simple event"

  let(:resource) { create(:candidacy) }
  let(:participatory_space) { resource }
  let(:event_name) { "decidim.events.candidacy_sent_to_technical_validation" }
  let(:admin_candidacy_path) { "/candidacies/#{resource.slug}" }
  let(:admin_candidacy_url) { "http://#{organization.host}:#{Capybara.server_port}#{admin_candidacy_path}" }
  let(:email_subject) { "Candidacy \"#{resource_title}\" was sent to technical validation." }
  let(:email_intro) { %(The candidacy "#{resource_title}" has been sent to technical validation. Check it out at <a href="#{admin_candidacy_url}">the admin panel</a>) }
  let(:email_outro) { "You have received this notification because you are an admin of the platform." }
  let(:notification_title) { %(The candidacy "#{resource_title}" has been sent to technical validation. Check it out at <a href="#{admin_candidacy_path}">the admin panel</a>) }

  # it_behaves_like "a simple event"
  # it_behaves_like "a simple event email"
  # it_behaves_like "a simple event notification"
end
