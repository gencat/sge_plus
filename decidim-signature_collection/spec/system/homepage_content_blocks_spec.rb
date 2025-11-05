# frozen_string_literal: true

require "spec_helper"

describe "Homepage candidacies content blocks" do
  let(:organization) { create(:organization) }
  let!(:candidacy) { create(:candidacy, organization:) }
  let!(:closed_candidacy) { create(:candidacy, :rejected, organization:) }

  before do
    create(:content_block, organization:, scope_name: :homepage, manifest_name: :highlighted_candidacies)
    switch_to_host(organization.host)
  end

  it "includes active candidacies to the homepage" do
    visit decidim.root_path

    within "#highlighted-candidacies" do
      expect(page).to have_i18n_content(candidacy.title)
      expect(page).not_to have_i18n_content(closed_candidacy.title)
    end
  end
end
