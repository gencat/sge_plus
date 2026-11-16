# frozen_string_literal: true

require "spec_helper"

describe "User prints the candidacy" do
  include_context "when admins candidacy"

  def edit_candidacy
    within("tr", text: translated(candidacy.title)) do
      find("button[data-controller='dropdown']").click
      click_on "Edit"
    end
  end

  def submit_and_validate
    within("[data-content]") do
      find("*[type=submit]").click
    end

    expect(page).to have_admin_callout "The candidacy has been successfully updated."
  end

  context "when candidacy update" do
    context "and user is admin" do
      let(:attributes) { attributes_for(:candidacy, organization:) }

      before do
        switch_to_host(organization.host)
        login_as user, scope: :user
        visit decidim_admin_candidacies.candidacies_path
      end

      it "updates the candidacy" do
        edit_candidacy

        fill_in_i18n(
          :candidacy_title,
          "#candidacy-title-tabs",
          **attributes[:title].except("machine_translations")
        )
        fill_in_i18n_editor(
          :candidacy_description,
          "#candidacy-description-tabs",
          **attributes[:description].except("machine_translations")
        )
        submit_and_validate

        visit decidim_admin.root_path
        expect(page).to have_content("updated the #{translated(attributes[:title])} candidacy")
      end

      context "when candidacy is in created state" do
        before do
          candidacy.created!
        end

        it "updates type, scope and signature type" do
          edit_candidacy
          within ".edit_candidacy" do
            select translated(other_candidacies_type.title), from: "candidacy_type_id"
            select translated(other_candidacies_type_scope.scope.name), from: "candidacy_decidim_scope_id"
            select "In-person", from: "candidacy_signature_type"
          end
          submit_and_validate
          expect(candidacy.reload.signature_type).to eq("offline")
        end

        it "displays candidacy attachments" do
          edit_candidacy
          expect(page).to have_link("Edit")
          expect(page).to have_link("New")
        end
      end

      context "when candidacy is in validating state" do
        before do
          candidacy.validating!
        end

        it "updates type, scope and signature type" do
          edit_candidacy
          within ".edit_candidacy" do
            select translated(other_candidacies_type.title), from: "candidacy_type_id"
            select translated(other_candidacies_type_scope.scope.name), from: "candidacy_decidim_scope_id"
            select "In-person", from: "candidacy_signature_type"
          end
          submit_and_validate
          expect(candidacy.reload.signature_type).to eq("offline")
        end

        it "displays candidacy attachments" do
          edit_candidacy
          expect(page).to have_link("Edit")
          expect(page).to have_link("New")
        end
      end

      context "when candidacy is in accepted state" do
        before do
          candidacy.accepted!
        end

        it "update of type, scope and signature type are disabled" do
          edit_candidacy

          within ".edit_candidacy" do
            expect(page).to have_css("#candidacy_type_id[disabled]")
            expect(page).to have_css("#candidacy_decidim_scope_id[disabled]")
            expect(page).to have_css("#candidacy_signature_type[disabled]")
          end
        end

        it "displays candidacy attachments" do
          edit_candidacy
          expect(page).to have_link("Edit")
          expect(page).to have_link("New")
        end
      end

      context "when there is a single candidacy type" do
        let!(:other_candidacies_type) { nil }
        let!(:other_candidacies_type_scope) { nil }

        before do
          candidacy.created!
        end

        it "update of type, scope and signature type are disabled" do
          edit_candidacy

          within ".edit_candidacy" do
            expect(page).to have_no_css("label[for='candidacy_type_id']")
            expect(page).to have_no_css("#candidacy_type_id")
          end
        end
      end
    end
  end
end
