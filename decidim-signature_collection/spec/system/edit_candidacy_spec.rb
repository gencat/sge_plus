# frozen_string_literal: true

require "spec_helper"

describe "Edit candidacy" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:candidacy_title) { translated(candidacy.title) }
  let(:new_title) { "This is my candidacy new title" }

  let!(:candidacy_type) { create(:candidacies_type, :attachments_enabled, :online_signature_enabled, organization:) }
  let!(:scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }

  let!(:other_candidacy_type) { create(:candidacies_type, :attachments_enabled, organization:) }
  let!(:other_scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }

  let(:candidacy_path) { decidim_candidacies.candidacy_path(candidacy) }
  let(:edit_candidacy_path) { decidim_candidacies.edit_candidacy_path(candidacy) }

  shared_examples "manage update" do
    it "can be updated" do
      visit candidacy_path

      within ".candidacy__aside" do
        click_on("Edit")
      end

      expect(page).to have_content "Edit Candidacy"

      within "form.edit_candidacy" do
        fill_in :candidacy_title, with: new_title
        click_on "Update"
      end

      expect(page).to have_content(new_title)
    end
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  describe "when user is candidacy author" do
    let(:candidacy) { create(:candidacy, :created, author: user, scoped_type:, organization:) }

    it_behaves_like "manage update"

    it "does not show the header's edit link" do
      visit candidacy_path

      within ".main-bar" do
        expect(page).to have_no_link("Edit")
      end
    end

    it "does not have status field" do
      expect(page).to have_no_xpath("//select[@id='candidacy_state']")
    end

    it "allows adding attachments" do
      visit candidacy_path

      click_on("Edit")

      expect(page).to have_content "Edit Candidacy"

      expect(candidacy.reload.attachments.count).to eq(0)

      dynamically_attach_file(:candidacy_documents, Decidim::Dev.asset("Exampledocument.pdf"))
      dynamically_attach_file(:candidacy_photos, Decidim::Dev.asset("avatar.jpg"))

      within "form.edit_candidacy" do
        click_on "Update"
      end

      expect(candidacy.reload.documents.count).to eq(1)
      expect(candidacy.photos.count).to eq(1)
      expect(candidacy.attachments.count).to eq(2)
    end

    context "when candidacy is published" do
      let(:candidacy) { create(:candidacy, author: user, scoped_type:, organization:) }

      it "cannot be updated" do
        visit decidim_candidacies.candidacy_path(candidacy)

        expect(page).to have_no_content "Edit candidacy"

        visit edit_candidacy_path

        expect(page).to have_content("not authorized")
      end
    end
  end

  describe "when author is a committee member" do
    let(:candidacy) { create(:candidacy, :created, scoped_type:, organization:) }

    before do
      create(:candidacies_committee_member, user:, candidacy:)
    end

    it_behaves_like "manage update"
  end

  describe "when user is admin" do
    let(:user) { create(:user, :confirmed, :admin, organization:) }
    let(:candidacy) { create(:candidacy, :created, scoped_type:, organization:) }

    it_behaves_like "manage update"
  end

  describe "when author is not a committee member" do
    let(:candidacy) { create(:candidacy, :created, scoped_type:, organization:) }

    it "renders an error" do
      visit decidim_candidacies.candidacy_path(candidacy)

      expect(page).to have_no_content("Edit candidacy")

      visit edit_candidacy_path

      expect(page).to have_content("not authorized")
    end
  end

  context "when rich text editor is enabled for participants" do
    let(:candidacy) { create(:candidacy, :created, author: user, scoped_type:, organization:) }
    let(:organization) { create(:organization, rich_text_editor_in_public_views: true) }

    before do
      visit candidacy_path

      click_on("Edit")

      expect(page).to have_content "Edit Candidacy"
    end

    it_behaves_like "having a rich text editor", "edit_candidacy", "content"
  end
end
