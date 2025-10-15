# frozen_string_literal: true

require "spec_helper"

describe "Admin manages candidacies types" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let!(:candidacies_type) { create(:candidacies_type, organization:) }
  let(:attributes) { attributes_for(:candidacies_type) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_candidacies.candidacies_types_path
  end

  context "when accessing candidacy types list" do
    it "shows the candidacy type data" do
      expect(page).to have_i18n_content(candidacies_type.title)
    end
  end

  context "when creating an candidacy type" do
    it "creates the candidacy type" do
      click_on "New candidacy type"

      fill_in_i18n(
        :candidacies_type_title,
        "#candidacies_type-title-tabs",
        **attributes[:title].except("machine_translations")
      )

      fill_in_i18n_editor(
        :candidacies_type_description,
        "#candidacies_type-description-tabs",
        **attributes[:description].except("machine_translations")
      )

      select("Online", from: "Signature type")

      dynamically_attach_file(:candidacies_type_banner_image, Decidim::Dev.asset("city2.jpeg"))

      click_on "Create"

      expect(page).to have_admin_callout("A new candidacy type has been successfully created")

      visit decidim_admin.root_path
      expect(page).to have_content("created the #{translated(attributes[:title])} candidacies type")
    end
  end

  context "when updating an candidacy type" do
    it "updates the candidacy type" do
      within "tr", text: translated(candidacies_type.title) do
        page.find(".action-icon--edit").click
      end

      fill_in_i18n(
        :candidacies_type_title,
        "#candidacies_type-title-tabs",
        **attributes[:title].except("machine_translations")
      )
      fill_in_i18n_editor(
        :candidacies_type_description,
        "#candidacies_type-description-tabs",
        **attributes[:description].except("machine_translations")
      )

      select("Mixed", from: "Signature type")
      check "Enable attachments"
      uncheck "Enable participants to undo their online signatures"
      check "Enable authors to choose the end of signature collection period"
      check "Enable authors to choose the area for their candidacy"
      uncheck "Enable comments"

      click_on "Update"

      expect(page).to have_admin_callout("The candidacy type has been successfully updated")

      visit decidim_admin.root_path
      expect(page).to have_content("updated the #{translated(attributes[:title])} candidacies type")
    end
  end

  context "when deleting an candidacy type" do
    it "deletes the candidacy type" do
      within "tr", text: translated(candidacies_type.title) do
        accept_confirm do
          page.find(".action-icon--remove").click
        end
      end

      expect(page).to have_admin_callout("The candidacy type has been successfully removed")
    end
  end
end
