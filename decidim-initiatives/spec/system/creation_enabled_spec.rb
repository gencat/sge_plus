# frozen_string_literal: true

require "rails_helper"

describe "Initiatives creation setting" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:initiative) { build(:initiative) }

  let(:initiatives_type_minimum_committee_members) { 2 }
  let(:initiatives_type) do
    create(
      :initiatives_type,
      organization:,
      minimum_committee_members: initiatives_type_minimum_committee_members
    )
  end
  let(:scoped_type) { create(:initiatives_type_scope, type: initiatives_type) }

  before do
    switch_to_host(organization.host)
    login_as(user, scope: :user)
    # Ensure there is at least one published initiative type with a scope so the
    # initiatives area is considered configured by the admin and the UI can
    # render the "New initiative" button when creation is enabled.
    initiatives_type
    scoped_type
  end

  it "does not show the New initiative button when creation is disabled" do
    Decidim::InitiativesSettings.find_or_create_by!(organization: organization, creation_enabled: false)
    visit decidim_initiatives.initiatives_path

    expect(page).to have_no_content("New initiative")
  end

  it "shows the New initiative button when creation is enabled" do
    Decidim::InitiativesSettings.find_or_create_by!(organization: organization, creation_enabled: true)
    visit decidim_initiatives.initiatives_path

    expect(page).to have_content("New initiative")
  end
end
