# frozen_string_literal: true

require "spec_helper"

describe "Candidacies creation setting" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:candidacy) { build(:candidacy) }

  let(:candidacies_type_minimum_committee_members) { 2 }
  let(:candidacies_type) do
    create(
      :candidacies_type,
      organization:,
      minimum_committee_members: candidacies_type_minimum_committee_members
    )
  end
  let(:scoped_type) { create(:candidacies_type_scope, type: candidacies_type) }

  before do
    switch_to_host(organization.host)
    login_as(user, scope: :user)
    # Ensure there is at least one published candidacy type with a scope so the
    # candidacies area is considered configured by the admin and the UI can
    # render the "New candidacy" button when creation is enabled.
    candidacies_type
    scoped_type
  end

  it "does not show the New candidacy button when creation is disabled" do
    Decidim::SignatureCollection::CandidaciesSettings.find_or_create_by!(organization: organization, creation_enabled: false)
    visit decidim_candidacies.candidacies_path

    expect(page).to have_no_content("New candidacy")
  end

  it "shows the New candidacy button when creation is enabled" do
    Decidim::SignatureCollection::CandidaciesSettings.find_or_create_by!(organization: organization, creation_enabled: true)
    visit decidim_candidacies.candidacies_path

    expect(page).to have_content("New candidacy")
  end
end
