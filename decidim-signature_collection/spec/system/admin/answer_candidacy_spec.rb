# frozen_string_literal: true

require "spec_helper"

describe "User answers the candidacy" do
  include_context "when admins candidacy"

  def submit_and_validate(message)
    within "[data-content]" do
      find("*[type=submit]").click
    end

    expect(page).to have_admin_callout(message)
  end

  context "when user is admin" do
    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_candidacies.candidacies_path
    end

    it "answer is allowed" do
      expect(page).to have_css(".action-icon--answer")
      page.find(".action-icon--answer").click

      within ".edit_candidacy_answer" do
        fill_in_i18n_editor(
          :candidacy_answer,
          "#candidacy-answer-tabs",
          en: "An answer",
          es: "Una respuesta",
          ca: "Una resposta"
        )
      end

      submit_and_validate("The candidacy has been successfully updated")
    end

    context "when candidacy is in published state" do
      before do
        candidacy.open!
      end

      context "and signature dates are editable" do
        it "can be edited in answer" do
          page.find(".action-icon--answer").click

          within ".edit_candidacy_answer" do
            fill_in_i18n_editor(
              :candidacy_answer,
              "#candidacy-answer-tabs",
              en: "An answer",
              es: "Una respuesta",
              ca: "Una resposta"
            )
            expect(page).to have_css("#candidacy_signature_start_date_date")
            expect(page).to have_css("#candidacy_signature_end_date_date")

            fill_in_datepicker :candidacy_signature_start_date_date, with: 1.day.ago.strftime("%d/%m/%Y")
          end

          submit_and_validate("The candidacy has been successfully updated")
        end

        context "when dates are invalid" do
          it "returns an error message" do
            page.find(".action-icon--answer").click

            within ".edit_candidacy_answer" do
              fill_in_i18n_editor(
                :candidacy_answer,
                "#candidacy-answer-tabs",
                en: "An answer",
                es: "Una respuesta",
                ca: "Una resposta"
              )
              expect(page).to have_css("#candidacy_signature_start_date_date")
              expect(page).to have_css("#candidacy_signature_end_date_date")

              fill_in :candidacy_signature_start_date_date, with: nil, fill_options: { clear: :backspace }
              fill_in_datepicker :candidacy_signature_start_date_date, with: 1.month.since(candidacy.signature_end_date).strftime("%d/%m/%Y")
            end

            submit_and_validate("There was a problem updating the candidacy.")
            expect(page).to have_current_path decidim_admin_candidacies.edit_candidacy_answer_path(candidacy)
          end
        end
      end
    end

    context "when candidacy is in validating state" do
      before do
        candidacy.validating!
      end

      it "signature dates are not displayed" do
        page.find(".action-icon--answer").click

        within ".edit_candidacy_answer" do
          expect(page).to have_no_css("#candidacy_signature_start_date_date")
          expect(page).to have_no_css("#candidacy_signature_end_date_date")
        end
      end

      it "shows the return_to_create_state checkbox" do
        page.find(".action-icon--answer").click

        within ".edit_candidacy_answer" do
          expect(page).to have_content("Return to creation state")
        end
      end
    end
  end
end
