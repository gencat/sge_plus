# frozen_string_literal: true

require "spec_helper"

describe "Explore versions", versioning: true do
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }

  let(:form) do
    Decidim::SignatureCollection::Admin::CandidacyForm.from_params(
      title: { en: "A reasonable candidacy title" },
      description: { en: "A reasonable candidacy description" },
      signature_start_date: candidacy.signature_start_date,
      signature_end_date: candidacy.signature_end_date
    ).with_context(
      current_organization: organization,
      current_component: nil,
      current_user: user,
      candidacy:
    )
  end
  let(:command) { Decidim::SignatureCollection::Admin::UpdateCandidacy.new(form, candidacy) }
  let(:candidacy_path) { decidim_candidacies.candidacy_path(candidacy) }

  before do
    switch_to_host(organization.host)
  end

  context "when visiting an candidacy details" do
    it "has only one version" do
      visit candidacy_path

      expect(page).to have_content("Version number 1 (of 1)")
    end

    it "shows the versions index" do
      visit candidacy_path

      expect(page).to have_link I18n.t("decidim.versions.resource_version.see_other_versions")
    end

    context "when updating an candidacy" do
      before do
        command.call
      end

      it "creates a new version" do
        visit candidacy_path

        expect(page).to have_content("Version number 2 (of 2)")
      end
    end
  end

  context "when visiting versions index" do
    before do
      command.call
      visit candidacy_path
      click_on I18n.t("decidim.versions.resource_version.see_other_versions")
    end

    it "lists all versions" do
      expect(page).to have_link(I18n.t("decidim.versions_list_item.show.version_index", index: 2, total: 2))
      expect(page).to have_link(I18n.t("decidim.versions_list_item.show.version_index", index: 1, total: 2))
    end
  end

  context "when showing version" do
    before do
      command.call
      visit candidacy_path
      click_on I18n.t("decidim.versions.resource_version.see_other_versions")
      click_on(I18n.t("decidim.versions_list_item.show.version_index", index: 2, total: 2))
    end

    it_behaves_like "accessible page"

    it "shows the creation date" do
      within ".version__author" do
        expect(page).to have_content(Time.zone.today.strftime("%d/%m/%Y"))
      end
    end

    it "shows the changed attributes" do
      expect(page).to have_content(I18n.t("decidim.versions.version.show.changes_at_title", title: translated(candidacy.title, locale: :en)))

      title_diff = find(".version__diff", text: "Title")
      within(title_diff) do
        expect(page).to have_content("Title")
        expect(page).to have_css(".diff > ul > .ins")
        expect(page).to have_content(translated(candidacy.title, locale: :en))
      end

      description_diff = find(".version__diff", text: "Description")
      within(description_diff) do
        expect(page).to have_content("Description")
        expect(page).to have_css(".diff > ul > .ins")
        expect(page).to have_content(ActionView::Base.full_sanitizer.sanitize(translated(candidacy.description, locale: :en), tags: []))
      end
    end
  end
end
