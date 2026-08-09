# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::Engine do
  it_behaves_like "clean engine"

  it "loads engine mailer previews" do
    expect(ActionMailer::Preview.all).to include(Decidim::Candidacies::CandidaciesMailerPreview)
  end
end
