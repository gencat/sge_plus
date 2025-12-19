# frozen_string_literal: true

require "spec_helper"

describe "Admin export candidacies' signature" do
  include_context "when admins candidacy"

  let!(:votes) { create_list(:candidacy_user_vote, 5, candidacy:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  it "downloads the PDF file", :download do
    visit decidim_admin_candidacies.candidacies_path

    within "tr", text: translated(candidacy.title) do
      page.find(".action-icon--edit").click
    end

    click_on "Export PDF of signatures"

    expect(File.basename(download_path)).to include("signatures_#{candidacy.id}.pdf")
  end
end
