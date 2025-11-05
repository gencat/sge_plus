# frozen_string_literal: true

require "spec_helper"

describe "Admin manages candidacies types scopes" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:candidacies_type) { create(:candidacies_type, organization:) }
  let!(:scope) { create(:scope, organization:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_candidacies.edit_candidacies_type_path(candidacies_type)
  end

  context "when creating a new candidacy type scope" do
    it "Creates a new candidacy type scope" do
      click_on "New candidacy type scope"
      select translated(scope.name), from: :candidacies_type_scope_decidim_scopes_id
      fill_in :candidacies_type_scope_supports_required, with: 1000
      click_on "Create"

      expect(page).to have_admin_callout("A new scope for the given candidacy type has been created")
    end

    it "allows creating candidacy type scopes with a Global scope" do
      click_on "New candidacy type scope"
      fill_in :candidacies_type_scope_supports_required, with: 10
      click_on "Create"

      expect(page).to have_admin_callout("A new scope for the given candidacy type has been created")

      within ".edit_candidacy_type" do
        expect(page).to have_content("Global scope")
      end
    end
  end

  context "when editing an candidacy type scope" do
    let!(:candidacy_type_scope) { create(:candidacies_type_scope, type: candidacies_type) }

    before do
      visit decidim_admin_candidacies.edit_candidacies_type_path(candidacies_type)
    end

    it "updates the candidacy type scope" do
      click_on "Configure"
      click_on "Update"

      expect(page).to have_admin_callout("The scope has been successfully updated")
    end
  end
end
