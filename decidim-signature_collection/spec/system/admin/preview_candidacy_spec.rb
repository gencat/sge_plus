# frozen_string_literal: true

require "spec_helper"

describe "User previews candidacy" do
  include_context "when admins candidacy"

  context "when candidacy preview" do
    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_candidacies.candidacies_path
    end

    it "shows the details of the given candidacy" do
      preview_window = window_opened_by do
        page.find(".action-icon--preview").click
      end

      within_window(preview_window) do
        within "[data-content]" do
          expect(page).to have_content(translated(candidacy.title, locale: :en))
          expect(page).to have_content(ActionView::Base.full_sanitizer.sanitize(translated(candidacy.description, locale: :en), tags: []))
          expect(page).to have_content(translated(candidacy.type.title, locale: :en))
          expect(page).to have_content(translated(candidacy.scope.name, locale: :en))
        end
      end
    end
  end
end
