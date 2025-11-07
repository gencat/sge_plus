# frozen_string_literal: true

require "spec_helper"

describe "Candidacy" do
  let(:organization) { create(:organization, available_authorizations: authorizations) }
  let(:do_not_require_authorization) { true }
  let(:authorizations) { %w(dummy_authorization_handler another_dummy_authorization_handler) }
  let!(:authorized_user) { create(:user, :confirmed, organization:) }
  let!(:authorization) { create(:authorization, user: authorized_user) }
  let(:login) { true }
  let(:candidacy_type_minimum_committee_members) { 2 }
  let(:signature_type) { "any" }
  let(:candidacy_type_promoting_committee_enabled) { true }
  let(:candidacy_type) do
    create(:candidacies_type, :attachments_enabled,
           organization:,
           minimum_committee_members: candidacy_type_minimum_committee_members,
           promoting_committee_enabled: candidacy_type_promoting_committee_enabled,
           signature_type:)
  end
  let!(:candidacy_type_scope) { create(:candidacies_type_scope, type: candidacy_type) }
  let!(:candidacy_type_scope2) { create(:candidacies_type_scope, type: candidacy_type) }
  let!(:other_candidacy_type) { create(:candidacies_type, :attachments_enabled, organization:) }
  let!(:other_candidacy_type_scope) { create(:candidacies_type_scope, type: other_candidacy_type) }
  let(:third_candidacy_type) { create(:candidacies_type, :attachments_enabled, organization:) }

  shared_examples "candidacies path redirection" do
    it "redirects to candidacies path" do
      accept_confirm do
        click_on("Send my candidacy to technical validation")
      end

      expect(page).to have_current_path("/candidacies")
    end
  end

  before do
    switch_to_host(organization.host)
    login_as(authorized_user, scope: :user) if authorized_user && login
    visit decidim_candidacies.candidacies_path
    allow(Decidim::SignatureCollection.config).to receive(:do_not_require_authorization).and_return(do_not_require_authorization)
  end

  context "when user visits the candidacies wizard and is not logged in" do
    let(:login) { false }
    let(:do_not_require_authorization) { false }
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
    let(:do_not_require_authorization) { false }
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

  describe "create candidacy verification" do
    context "when there is just one candidacy type" do
      let!(:other_candidacy_type) { nil }
      let!(:other_candidacy_type_scope) { nil }

      context "when the user is logged in" do
        context "and they do not need to be verified" do
          it "they are taken to the candidacy form" do
            click_on "New candidacy"
            expect(page).to have_content("Create a new candidacy")
          end
        end

        context "and creation require a verification" do
          before do
            allow(Decidim::SignatureCollection.config).to receive(:do_not_require_authorization).and_return(false)
            visit decidim_candidacies.candidacies_path
          end

          context "and they are verified" do
            it "they are taken to the candidacy form" do
              click_on "New candidacy"
              expect(page).to have_content("Create a new candidacy")
            end
          end

          context "and they are not verified" do
            let(:authorization) { nil }

            it "they need to verify" do
              click_on "New candidacy"
              expect(page).to have_content("Authorization required")
            end

            it "they are redirected to the candidacy form after verifying" do
              click_on "New candidacy"
              click_on "View authorizations"
              click_on(text: /Example authorization/)
              fill_in "Document number", with: "123456789X"
              click_on "Send"
              expect(page).to have_content("Review the content of your candidacy.")
            end
          end
        end

        context "and an authorization handler has been activated" do
          before do
            candidacy_type.create_resource_permission(
              permissions: {
                "create" => {
                  "authorization_handlers" => {
                    "dummy_authorization_handler" => { "options" => {} }
                  }
                }
              }
            )
            visit decidim_candidacies.candidacies_path
          end

          let(:authorization) { nil }

          it "they need to verify" do
            click_on "New candidacy"
            expect(page).to have_content("We need to verify your identity")
          end

          it "they are authorized to create after verifying" do
            click_on "New candidacy"
            fill_in "Document number", with: "123456789X"
            click_on "Send"
            expect(page).to have_content("Review the content of your candidacy. ")
          end
        end
      end

      context "when they are not logged in" do
        let(:login) { false }

        it "they need to login in" do
          click_on "New candidacy"
          expect(page).to have_content("Please log in")
        end

        context "when they do not need to be verified" do
          it "they are redirected to the candidacy form after log in" do
            click_on "New candidacy"
            within "#loginModal" do
              fill_in "Email", with: authorized_user.email
              fill_in "Password", with: "decidim123456789"
              click_on "Log in"
            end

            expect(page).to have_content("Create a new candidacy")
          end
        end

        context "and creation require a verification" do
          before do
            allow(Decidim::SignatureCollection.config).to receive(:do_not_require_authorization).and_return(false)
          end

          context "and they are verified" do
            it "they are redirected to the candidacy form after log in" do
              click_on "New candidacy"
              within "#loginModal" do
                fill_in "Email", with: authorized_user.email
                fill_in "Password", with: "decidim123456789"
                click_on "Log in"
              end

              expect(page).to have_content("Create a new candidacy")
            end
          end

          context "and they are not verified" do
            let(:authorization) { nil }

            it "they are shown an error" do
              click_on "New candidacy"
              within "#loginModal" do
                fill_in "Email", with: authorized_user.email
                fill_in "Password", with: "decidim123456789"
                click_on "Log in"
              end

              expect(page).to have_content("You are not authorized to perform this action")
            end
          end
        end

        context "and an authorization handler has been activated" do
          before do
            candidacy_type.create_resource_permission(
              permissions: {
                "create" => {
                  "authorization_handlers" => {
                    "dummy_authorization_handler" => { "options" => {} }
                  }
                }
              }
            )
            visit decidim_candidacies.candidacies_path
          end

          let(:authorization) { nil }

          it "they are redirected to authorization form page" do
            click_on "New candidacy"
            within "#loginModal" do
              fill_in "Email", with: authorized_user.email
              fill_in "Password", with: "decidim123456789"
              click_on "Log in"
            end

            expect(page).to have_content("We need to verify your identity")
            expect(page).to have_content("Verify with Example authorization")
          end
        end

        context "and more than one authorization handlers has been activated" do
          before do
            candidacy_type.create_resource_permission(
              permissions: {
                "create" => {
                  "authorization_handlers" => {
                    "dummy_authorization_handler" => { "options" => {} },
                    "another_dummy_authorization_handler" => { "options" => {} }
                  }
                }
              }
            )
            visit decidim_candidacies.candidacies_path
          end

          let(:authorization) { nil }

          it "they are redirected to pending onboarding authorizations page" do
            click_on "New candidacy"
            within "#loginModal" do
              fill_in "Email", with: authorized_user.email
              fill_in "Password", with: "decidim123456789"
              click_on "Log in"
            end

            expect(page).to have_content("You are almost ready to create an candidacy")
            expect(page).to have_css("a[data-verification]", count: 2)
          end
        end
      end
    end

    context "when there are multiples candidacy type" do
      context "when the user is logged in" do
        context "and they do not need to be verified" do
          it "they are taken to the candidacy form" do
            click_on "New candidacy"
            expect(page).to have_content("Which candidacy do you want to launch")
          end
        end

        context "and creation require a verification" do
          before do
            allow(Decidim::SignatureCollection.config).to receive(:do_not_require_authorization).and_return(false)
          end

          context "and they are verified" do
            it "they are taken to the candidacy form" do
              click_on "New candidacy"
              expect(page).to have_content("Which candidacy do you want to launch")
            end
          end

          context "and they are not verified" do
            let(:authorization) { nil }

            it "they need to verify" do
              click_on "New candidacy"
              expect(page).to have_css("a[data-dialog-open=not-authorized-modal]", visible: :all, count: 2)
            end

            it "they are redirected to the candidacy form after verifying" do
              click_on "New candidacy"
              click_on "Verify your account to promote this candidacy", match: :first
              click_on "View authorizations"
              click_on(text: /Example authorization/)
              fill_in "Document number", with: "123456789X"
              click_on "Send"
              expect(page).to have_content("Which candidacy do you want to launch")
            end
          end
        end

        context "and an authorization handler has been activated on the first candidacy type" do
          before do
            candidacy_type.create_resource_permission(
              permissions: {
                "create" => {
                  "authorization_handlers" => {
                    "dummy_authorization_handler" => { "options" => {} }
                  }
                }
              }
            )
            visit decidim_candidacies.candidacies_path
          end

          let(:authorization) { nil }

          it "they need to verify" do
            click_on "New candidacy"
            click_on "Verify your account to promote this candidacy", match: :first
            expect(page).to have_content("We need to verify your identity")
          end

          it "they are authorized to create after verifying" do
            click_on "New candidacy"
            click_on "Verify your account to promote this candidacy", match: :first
            fill_in "Document number", with: "123456789X"
            click_on "Send"
            expect(page).to have_content("Review the content of your candidacy.")
          end
        end
      end

      context "when they are not logged in" do
        let(:login) { false }

        it "they need to login in" do
          click_on "New candidacy"
          expect(page).to have_content("Please log in")
        end

        context "when they do not need to be verified" do
          it "they are redirected to the candidacy form after log in" do
            click_on "New candidacy"
            within "#loginModal" do
              fill_in "Email", with: authorized_user.email
              fill_in "Password", with: "decidim123456789"
              click_on "Log in"
            end

            expect(page).to have_content("Which candidacy do you want to launch")
          end
        end

        context "and creation require a verification" do
          before do
            allow(Decidim::SignatureCollection.config).to receive(:do_not_require_authorization).and_return(false)
          end

          context "and they are verified" do
            it "they are redirected to the candidacy form after log in" do
              click_on "New candidacy"
              within "#loginModal" do
                fill_in "Email", with: authorized_user.email
                fill_in "Password", with: "decidim123456789"
                click_on "Log in"
              end

              expect(page).to have_content("Which candidacy do you want to launch")
            end
          end

          context "and they are not verified" do
            let(:authorization) { nil }

            it "they are shown an error" do
              click_on "New candidacy"
              within "#loginModal" do
                fill_in "Email", with: authorized_user.email
                fill_in "Password", with: "decidim123456789"
                click_on "Log in"
              end

              expect(page).to have_css("a[data-dialog-open=not-authorized-modal]", visible: :all, count: 2)
            end
          end
        end

        context "and an authorization handler has been activated" do
          before do
            candidacy_type.create_resource_permission(
              permissions: {
                "create" => {
                  "authorization_handlers" => {
                    "dummy_authorization_handler" => { "options" => {} }
                  }
                }
              }
            )
            visit decidim_candidacies.candidacies_path
          end

          let(:authorization) { nil }

          it "they are redirected to the candidacy form after log in but need to verify" do
            click_on "New candidacy"
            within "#loginModal" do
              fill_in "Email", with: authorized_user.email
              fill_in "Password", with: "decidim123456789"
              click_on "Log in"
            end

            expect(page).to have_content("Create a new candidacy")
            click_on "Verify your account to promote this candidacy", match: :first
            expect(page).to have_content("We need to verify your identity")
          end
        end
      end
    end
  end

  context "when rich text editor is enabled for participants" do
    before do
      organization.update(rich_text_editor_in_public_views: true)
      click_on "New candidacy"
      first("button.card__highlight").click
    end

    it_behaves_like "having a rich text editor", "new_candidacy_form", "content"
  end

  describe "creating an candidacy" do
    context "without validation" do
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
          first("button.card__highlight").click
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
            expect(page).to have_content("Review the content of your candidacy.")
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
            expect(page).to have_content("Review the content of your candidacy.")
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
          let(:candidacy_type) { create(:candidacies_type, organization:, minimum_committee_members: candidacy_type_minimum_committee_members, signature_type:) }

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
            fill_in "Title", with: translated(candidacy.title, locale: :en)
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
            first("button.card__highlight").click
          end

          it "create view is shown" do
            expect(page).to have_content("Create")
          end

          it "offers contextual help" do
            within ".flash.secondary" do
              expect(page).to have_content("Review the content of your candidacy. Is your title easy to understand? Is the objective of your candidacy clear?")
              expect(page).to have_content("You have to choose the type of signature. In-person, online or a combination of both")
              expect(page).to have_content("Which is the geographic scope of the candidacy?")
            end
          end

          it "does not show the select input for candidacy_type" do
            expect(page).to have_no_content("Type")
            expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
          end

          it "shows input for signature collection type" do
            expect(page).to have_content("Signature collection type")
            expect(find(:xpath, "//select[@id='candidacy_signature_type']", visible: :all).value).to eq(candidacy_type.signature_type)
          end

          context "when only one signature collection and scope are available" do
            let(:candidacy_type_scope2) { nil }
            let(:candidacy_type) { create(:candidacies_type, organization:, minimum_committee_members: candidacy_type_minimum_committee_members, signature_type: "offline") }

            it "hides and automatically selects the values" do
              expect(page).to have_no_content("Signature collection type")
              expect(page).to have_no_content("Scope")
              expect(find(:xpath, "//input[@id='candidacy_type_id']", visible: :all).value).to eq(candidacy_type.id.to_s)
              expect(find(:xpath, "//input[@id='candidacy_signature_type']", visible: :all).value).to eq("offline")
            end
          end

          context "when the scope is not selected" do
            it "shows an error" do
              select("Online", from: "Signature collection type")
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
            let(:candidacy_type) { create(:candidacies_type, :custom_signature_end_date_enabled, organization:, minimum_committee_members: candidacy_type_minimum_committee_members, signature_type:) }

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
            let(:candidacy_type) { create(:candidacies_type, :area_enabled, organization:, minimum_committee_members: candidacy_type_minimum_committee_members, signature_type:) }

            it "shows the area" do
              expect(page).to have_content("Area")
            end
          end

          context "when rich text editor is enabled for participants" do
            before do
              expect(page).to have_content("Create")
              organization.update(rich_text_editor_in_public_views: true)

              visit current_path
            end

            it_behaves_like "having a rich text editor", "new_candidacy_form", "content"
          end
        end
      end

      context "when there is a promoter committee" do
        let(:candidacy) { build(:candidacy, organization:, scoped_type: candidacy_type_scope) }

        before do
          first("button.card__highlight").click

          fill_in "Title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select("Online", from: "Signature collection type")
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          find_button("Continue").click
        end

        it "shows the promoter committee" do
          expect(page).to have_content("Promoter committee")
        end

        it "offers contextual help" do
          within ".flash.secondary" do
            expect(page).to have_content("This kind of candidacy requires a Promoting Commission consisting of at least #{candidacy_type_minimum_committee_members} people (attestors). You must share the following link with the other people that are part of this candidacy. When your contacts receive this link they will have to follow the indicated steps.")
          end
        end

        it "contains a link to invite other users" do
          expect(page).to have_content("/committee_requests/new")
        end

        it "contains a button to continue with next step" do
          expect(page).to have_content("Continue")
        end

        context "when minimum committee size is zero" do
          let(:candidacy_type_minimum_committee_members) { 0 }

          it "skips to next step" do
            within("#wizard-steps [data-active]") do
              expect(page).to have_no_content("Promoter committee")
              expect(page).to have_content("Finish")
            end
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

      context "when the candidacy is created by an user group" do
        let(:organization) { create(:organization, available_authorizations: authorizations, user_groups_enabled: true) }
        let(:candidacy) { build(:candidacy) }
        let!(:user_group) { create(:user_group, :verified, organization:, users: [authorized_user]) }

        before do
          authorized_user.reload
          first("button.card__highlight").click

          fill_in "Title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select("Online", from: "Signature collection type")
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
        end

        it "shows the user group as author" do
          expect(Decidim::SignatureCollection::Candidacy.where(decidim_user_group_id: user_group.id).count).to eq(0)
          select(user_group.name, from: "Author")
          find_button("Continue").click
          expect(Decidim::SignatureCollection::Candidacy.where(decidim_user_group_id: user_group.id).count).to eq(1)
        end
      end

      context "when finish" do
        let(:candidacy) { build(:candidacy) }

        before do
          first("button.card__highlight").click

          fill_in "Title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select("Online", from: "Signature collection type")
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          dynamically_attach_file(:candidacy_documents, Decidim::Dev.asset("Exampledocument.pdf"))
          dynamically_attach_file(:candidacy_photos, Decidim::Dev.asset("avatar.jpg"))
          find_button("Continue").click
          find_link("Continue").click
          expect(page).to have_content("Your candidacy has been successfully created.")
        end

        it "saves the attachments" do
          expect(Decidim::SignatureCollection::Candidacy.last.documents.count).to eq(1)
          expect(Decidim::SignatureCollection::Candidacy.last.photos.count).to eq(1)
        end

        it "shows the page component" do
          find_link("Go to my candidacies").click
          find_link(translated(candidacy.title, locale: :en)).click

          within ".participatory-space__nav-container" do
            find_link("Page").click
          end

          expect(page).to have_content("Page")
        end

        context "when minimum committee size is above zero" do
          it "finish view is shown" do
            expect(page).to have_content("Finish")
          end

          it "Offers contextual help" do
            within ".flash.secondary" do
              expect(page).to have_content("Congratulations! Your candidacy has been successfully created.")
            end
          end

          it "displays an edit link" do
            expect(page).to have_link("Edit my candidacy")
          end
        end

        it "displays a link to take the user to their candidacies" do
          find_link("Edit my candidacy").click

          expect(page).to have_field("candidacy_title", with: translated(candidacy.title, locale: :en))
        end
      end

      context "when minimum committee size is zero" do
        let(:candidacy) { build(:candidacy, organization:, scoped_type: candidacy_type_scope) }
        let(:candidacy_type_minimum_committee_members) { 0 }
        let(:expected_message) { "You are going to send the candidacy for an admin to review it and publish it. Once published you will not be able to edit it. Are you sure?" }

        before do
          first("button.card__highlight").click

          fill_in "Title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select("Online", from: "Signature collection type")
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          find_button("Continue").click
        end

        it "displays a send to technical validation link" do
          expect(page).to have_link("Send my candidacy to technical validation")
          expect(page).to have_css "a[data-confirm='#{expected_message}']"
        end

        it_behaves_like "candidacies path redirection"
      end

      context "when promoting committee is not enabled" do
        let(:candidacy) { build(:candidacy, organization:, scoped_type: candidacy_type_scope) }
        let(:candidacy_type_promoting_committee_enabled) { false }
        let(:candidacy_type_minimum_committee_members) { 0 }
        let(:expected_message) { "You are going to send the candidacy for an admin to review it and publish it. Once published you will not be able to edit it. Are you sure?" }

        before do
          first("button.card__highlight").click

          fill_in "Title", with: translated(candidacy.title, locale: :en)
          fill_in "candidacy_description", with: translated(candidacy.description, locale: :en)
          select("Online", from: "Signature collection type")
          select(translated(candidacy_type_scope&.scope&.name, locale: :en), from: "Scope")
          find_button("Continue").click
        end

        it "displays a send to technical validation link" do
          expect(page).to have_link("Send my candidacy to technical validation")
          expect(page).to have_css "a[data-confirm='#{expected_message}']"
        end

        it_behaves_like "candidacies path redirection"
      end
    end
  end
end
