# frozen_string_literal: true

require "spec_helper"

describe "Candidacy" do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, :confirmed, organization:) }
  let(:login) { true }
  let(:signature_type) { "any" }
  let(:candidacy_type) do
    create(:candidacies_type, :attachments_enabled,
           organization:,
           signature_type:)
  end
  let!(:candidacies_settings) { create(:candidacies_settings, creation_enabled: true, organization:) }
  let!(:candidacy_type_scope) { create(:candidacies_type_scope, type: candidacy_type) }
  let!(:candidacy_type_scope2) { create(:candidacies_type_scope, type: candidacy_type) }
  let!(:other_candidacy_type) { create(:candidacies_type, :attachments_enabled, organization:) }
  let!(:other_candidacy_type_scope) { create(:candidacies_type_scope, type: other_candidacy_type) }
  let(:third_candidacy_type) { create(:candidacies_type, :attachments_enabled, organization:) }

  shared_examples "candidacies path redirection" do
    it "redirects to candidacies path" do
      accept_confirm do
        click_on("Send candidacy to technical validation")
      end

      expect(page).to have_current_path("/candidacies")
    end
  end

  before do
    switch_to_host(organization.host)
    login_as(user, scope: :user) if user && login
    visit decidim_candidacies.candidacies_path
  end

  context "when user visits the candidacies wizard and is not logged in" do
    let(:login) { false }
    let(:signature_type) { "online" }

    context "when there is only one candidacy type" do
      let!(:other_candidacy_type) { nil }
      let!(:other_candidacy_type_scope) { nil }

      [
        :select_candidacy_type,
        :fill_data,
        :promotal_committee,
        :finish
      ].each do |step|
        it "redirects to the login page when landing on #{step}" do
          expect(Decidim::SignatureCollection::CandidaciesType.count).to eq(1)
          visit decidim_candidacies.create_candidacy_path(step)
          expect(page).to have_current_path("/users/sign_in")
        end
      end
    end

    context "when there are more candidacy types" do
      [
        :select_candidacy_type,
        :fill_data,
        :promotal_committee,
        :finish
      ].each do |step|
        it "redirects to the login page when landing on #{step}" do
          expect(Decidim::SignatureCollection::CandidaciesType.count).to eq(2)
          visit decidim_candidacies.create_candidacy_path(step)
          expect(page).to have_current_path("/users/sign_in")
        end
      end
    end
  end

  context "when user requests a page not having all the data required" do
    let(:signature_type) { "online" }

    context "when there is only one candidacy type" do
      let!(:other_candidacy_type) { nil }
      let!(:other_candidacy_type_scope) { nil }

      [
        :select_candidacy_type,
        :fill_data,
        :promotal_committee,
        :finish
      ].each do |step|
        it "redirects to the previous_form page when landing on #{step}" do
          expect(Decidim::SignatureCollection::CandidaciesType.count).to eq(1)
          visit decidim_candidacies.create_candidacy_path(step)
          expect(page).to have_current_path(decidim_candidacies.create_candidacy_path(:fill_data))
        end
      end
    end

    context "when there are more candidacy types" do
      [
        :fill_data,
        :promotal_committee,
        :finish
      ].each do |step|
        it "redirects to the select_candidacy_type page when landing on #{step}" do
          expect(Decidim::SignatureCollection::CandidaciesType.count).to eq(2)
          visit decidim_candidacies.create_candidacy_path(step)
          expect(page).to have_current_path(decidim_candidacies.create_candidacy_path(:select_candidacy_type))
        end
      end
    end
  end

  describe "create candidacy" do
    context "when there is just one candidacy type" do
      let!(:other_candidacy_type) { nil }
      let!(:other_candidacy_type_scope) { nil }

      context "when the user is logged in" do
        it "they are taken to the candidacy form" do
          click_on "New candidacy"
          expect(page).to have_field("candidacy_title")
        end
      end

      context "when they are not logged in" do
        let(:login) { false }

        it "they need to login in" do
          click_on "New candidacy"
          expect(page).to have_content("You need to log in")
        end

        it "they are redirected to the candidacy form after log in" do
          click_on "New candidacy"
          within "#session_new_user" do
            fill_in "Email", with: user.email
            fill_in "Password", with: "decidim123456789"
            click_on "Log in"
          end

          expect(page).to have_field("candidacy_title")
        end
      end
    end

    context "when there are multiples candidacy type" do
      context "when the user is logged in" do
        it "they are taken to the candidacy form" do
          click_on "New candidacy"
          expect(page).to have_content("Which candidacy do you want to launch")
        end
      end

      context "when they are not logged in" do
        let(:login) { false }

        it "they need to login in" do
          click_on "New candidacy"
          expect(page).to have_content("Please log in")
        end

        it "they are redirected to the candidacy form after log in" do
          click_on "New candidacy"
          within "#loginModal" do
            fill_in "Email", with: user.email
            fill_in "Password", with: "decidim123456789"
            click_on "Log in"
          end

          expect(page).to have_content("Which candidacy do you want to launch")
        end
      end
    end
  end

  context "when rich text editor is enabled for participants" do
    before do
      organization.update(rich_text_editor_in_public_views: true)
      click_on "New candidacy"
      first(".card__highlight .button__secondary").click
    end

    it_behaves_like "having a rich text editor", "new_candidacy_form", "content"
  end

  describe "creating an candidacy" do
    context "with validation" do
      before do
        click_on "New candidacy"
      end

      context "and select candidacy type" do
        it "offers contextual help" do
          within ".flash.secondary" do
            expect(page).to have_content("Candidacies are a means by which the participants can intervene so that the organization can undertake actions in defence of the general interest. Which candidacy do you want to launch?")
          end
        end

        it "shows the available candidacy types" do
          within "[data-content]" do
            expect(page).to have_content(translated(candidacy_type.title, locale: :en))
            expect(page).to have_content(ActionView::Base.full_sanitizer.sanitize(translated(candidacy_type.description, locale: :en), tags: []))
          end
        end

        it "do not show candidacy types without related scopes" do
          within "[data-content]" do
            expect(page).to have_no_content(translated(third_candidacy_type.title, locale: :en))
            expect(page).to have_no_content(ActionView::Base.full_sanitizer.sanitize(translated(third_candidacy_type.description, locale: :en), tags: []))
          end
        end
      end

      context "and fill basic data" do
        before do
          first(".card__highlight .button__secondary").click
        end

        it "does not show the select input for candidacy_type" do
          expect(page).to have_no_content("Type")
          expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
        end

        it "have fields for title and description" do
          expect(page).to have_xpath("//input[@id='candidacy_title']")
          expect(page).to have_xpath("//textarea[@id='candidacy_description']", visible: :all)
        end

        it "does not have status field" do
          expect(page).to have_no_xpath("//select[@id='candidacy_state']")
        end

        it "offers contextual help" do
          within ".flash.secondary" do
            expect(page).to have_content("Remember that, prior to starting the collection of signatures")
          end
        end
      end

      context "when there is only one candidacy type" do
        let!(:other_candidacy_type) { nil }
        let!(:other_candidacy_type_scope) { nil }

        it "does not displays candidacy types" do
          expect(page).to have_no_current_path(decidim_candidacies.create_candidacy_path(id: :select_candidacy_type))
        end

        it "does not display the 'choose' step" do
          within ".wizard-steps" do
            expect(page).to have_no_content("Choose")
          end
        end

        it "has a hidden field with the selected candidacy type" do
          expect(page).to have_xpath("//input[@id='candidacy_type_id']", visible: :all)
          expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
        end

        it "have fields for title and description" do
          expect(page).to have_xpath("//input[@id='candidacy_title']")
          expect(page).to have_xpath("//textarea[@id='candidacy_description']", visible: :all)
        end

        it "does not have status field" do
          expect(page).to have_no_xpath("//select[@id='candidacy_state']")
        end

        it "offers contextual help" do
          within ".flash.secondary" do
            expect(page).to have_content("Remember that, prior to starting the collection of signatures")
          end
        end
      end

      context "when create candidacy" do
        let(:candidacy) { build(:candidacy) }

        context "when only one signature collection and scope are available" do
          let(:signature_type) { "offline" }
          let!(:other_candidacy_type) { nil }
          let!(:other_candidacy_type_scope) { nil }
          let(:candidacy_type_scope2) { nil }
          let(:candidacy_type) { create(:candidacies_type, organization:, signature_type:) }

          it "hides and automatically selects the values" do
            expect(page).to have_no_content("Signature collection type")
            expect(page).to have_no_content("Scope")
            expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
            expect(find(:xpath, "//input[@id='candidacy_signature_type']", visible: :all).value).to eq("offline")
          end
        end

        context "when there is only one candidacy type" do
          let!(:other_candidacy_type) { nil }
          let!(:other_candidacy_type_scope) { nil }

          before do
            fill_in "candidacy_title", with: translated(candidacy.title, locale: :en)
            fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
            find_button("Continue").click
          end

          it "does not show select input for candidacy_type" do
            expect(page).to have_no_content("Candidacy type")
            expect(page).to have_no_css("#candidacy_type_id")
          end

          it "has a hidden field with the selected candidacy type" do
            expect(page).to have_xpath("//input[@id='candidacy_type_id']", visible: :all)
            expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
          end
        end

        context "when there are several candidacy types" do
          before do
            first(".card__highlight .button__secondary").click
          end

          it "create view is shown" do
            expect(page).to have_content("Create")
          end

          it "offers contextual help" do
            within ".flash.secondary" do
              expect(page).to have_content("Remember that, prior to starting the collection of signatures")
            end
          end

          it "does not show the select input for candidacy_type" do
            expect(page).to have_no_content("Type")
            expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
          end

          it "does not let the user choose the signature collection type" do
            expect(page).to have_no_select("candidacy_signature_type")
            expect(page).to have_xpath("//input[@id='candidacy_signature_type']", visible: :all)
          end

          context "when only one signature collection and scope are available" do
            let(:candidacy_type_scope2) { nil }
            let(:candidacy_type) { create(:candidacies_type, organization:, signature_type: "offline") }

            it "hides and automatically selects the values" do
              expect(page).to have_no_content("Signature collection type")
              expect(page).to have_no_content("Scope")
              expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
              expect(find(:xpath, "//input[@id='candidacy_signature_type']", visible: :all).value).to eq("offline")
            end
          end

          context "when the scope is not selected" do
            it "shows an error" do
              find_button("Continue").click

              expect_blank_field_validation_message("#candidacy_scope_id", type: :select)
            end
          end

          context "when the candidacy type does not enable custom signature end date" do
            it "does not show the signature end date" do
              expect(page).to have_no_content("End of signature collection period")
            end
          end

          context "when the candidacy type enables custom signature end date" do
            let(:signature_type) { "offline" }
            let(:candidacy_type) { create(:candidacies_type, :custom_signature_end_date_enabled, organization:, signature_type:) }

            it "shows the signature end date" do
              expect(page).to have_content("End of signature collection period")
            end
          end

          context "when the candidacy type does not enable area" do
            it "does not show the area" do
              expect(page).to have_no_content("Area")
            end
          end

          context "when the candidacy type enables area" do
            let(:signature_type) { "offline" }
            let(:candidacy_type) { create(:candidacies_type, :area_enabled, organization:, signature_type:) }

            it "shows the area" do
              expect(page).to have_content("Area")
            end
          end
        end
      end

      context "when there is a promoter committee" do
        let(:candidacy) { build(:candidacy, organization:, scoped_type: candidacy_type_scope) }

        before do
          first(".card__highlight .button__secondary").click

          fill_in "candidacy_title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          find_button("Continue").click
        end

        it "skips to next step" do
          within("#wizard-steps [data-active]") do
            expect(page).to have_no_content("Promoter committee")
            expect(page).to have_content("Finish")
          end
        end

        context "and it is disabled at the type scope" do
          let(:candidacy_type) { create(:candidacies_type, organization:, promoting_committee_enabled: false, signature_type:) }

          it "skips the promoting committee settings" do
            expect(page).to have_no_content("Promoter committee")
            expect(page).to have_content("Finish")
          end
        end
      end

      context "when finish" do
        let(:candidacy) { build(:candidacy) }

        before do
          first(".card__highlight .button__secondary").click

          fill_in "candidacy_title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          dynamically_attach_file(:candidacy_documents, Decidim::Dev.asset("Exampledocument.pdf"))
          find_button("Continue").click
          # Wait for the navigation, so that the nodes of the previous page are not checked
          expect(page).to have_current_path(%r{create_candidacy/(promotal_committee|finish)})
          expect(page).to have_content("Congratulations! The process has been successfully initiated.")
        end

        it "saves the attachments" do
          attachments = Decidim::SignatureCollection::Candidacy.last.attachments

          expect(attachments.map { |attachment| attachment.file.filename.to_s }).to eq(["Exampledocument.pdf"])
        end

        context "when minimum committee size is above zero" do
          it "finish view is shown" do
            expect(page).to have_content("Finish")
          end

          it "Offers contextual help" do
            within ".flash.secondary" do
              expect(page).to have_content("Congratulations! The process has been successfully initiated.")
            end
          end

          it "displays an edit link" do
            expect(page).to have_link("Edit candidacy")
          end
        end

        it "displays a link to edit the candidacy" do
          find_link("Edit candidacy").click

          expect(page).to have_field("candidacy_title", with: translated(candidacy.title, locale: :en))
        end
      end

      context "when minimum committee size is zero" do
        let(:candidacy) { build(:candidacy, organization:, scoped_type: candidacy_type_scope) }
        let(:expected_message) { "You are going to send the candidacy for review and publication. Once published, you will not be able to edit it." }

        before do
          first(".card__highlight .button__secondary").click

          fill_in "candidacy_title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          find_button("Continue").click
        end

        it "displays a send to technical validation link" do
          expect(page).to have_link("Send candidacy to technical validation")
          expect(page).to have_css "a[data-confirm='#{expected_message}']"
        end

        it_behaves_like "candidacies path redirection"
      end

      context "when promoting committee is not enabled" do
        let(:candidacy) { build(:candidacy, organization:, scoped_type: candidacy_type_scope) }
        let(:candidacy_type_promoting_committee_enabled) { false }
        let(:expected_message) { "You are going to send the candidacy for review and publication. Once published, you will not be able to edit it." }

        before do
          first(".card__highlight .button__secondary").click

          fill_in "candidacy_title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          find_button("Continue").click
        end

        it "displays a send to technical validation link" do
          expect(page).to have_link("Send candidacy to technical validation")
          expect(page).to have_css "a[data-confirm='#{expected_message}']"
        end

        it_behaves_like "candidacies path redirection"
      end
    end
  end
end
