# frozen_string_literal: true

require "spec_helper"

describe "Admin exports candidacies" do
  include_context "with filterable context"

  let!(:candidacies) do
    create_list(:candidacy, 3, organization:)
  end

  let!(:created_candidacy) do
    create(:candidacy, :created, organization:)
  end

  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when accessing candidacies list" do
    it "shows the export dropdown" do
      visit decidim_admin_candidacies.candidacies_path

      expect(page).to have_content("Export all")
      expect(page).to have_no_content("Export selection")
    end
  end

  context "when clicking the export dropdown" do
    before do
      visit decidim_admin_candidacies.candidacies_path
    end

    it "shows the export formats" do
      find("span", text: "Export all").click

      expect(page).to have_content("Candidacies as CSV")
      expect(page).to have_content("Candidacies as JSON")
    end
  end

  context "when clicking the export link" do
    before do
      visit decidim_admin_candidacies.candidacies_path
      find("span", text: "Export all").click
    end

    it "displays success message" do
      click_on "Candidacies as JSON"

      expect(page).to have_content("Your export is currently in progress. You will receive an email when it is complete.")
    end
  end

  context "when candidacies are filtered" do
    context "when accessing candidacies list" do
      it "shows the export dropdown" do
        visit decidim_admin_candidacies.candidacies_path
        apply_filter("State", "Created")

        expect(page).to have_content("Export all")
        expect(page).to have_content("Export selection")
      end
    end

    context "when clicking the export dropdown" do
      before do
        visit decidim_admin_candidacies.candidacies_path
        apply_filter("State", "Created")
      end

      it "shows the export formats" do
        find("span", text: "Export selection").click

        expect(page).to have_content("Candidacies as CSV")
        expect(page).to have_content("Candidacies as JSON")
      end
    end

    context "when clicking the export link" do
      before do
        visit decidim_admin_candidacies.candidacies_path
        apply_filter("State", "Created")
        find("span", text: "Export selection").click
      end

      it "displays success message" do
        click_on "Candidacies as JSON"

        expect(page).to have_content("Your export is currently in progress. You will receive an email when it is complete.")
      end
    end
  end
end
