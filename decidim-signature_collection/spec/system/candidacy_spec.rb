# frozen_string_literal: true

require "spec_helper"

describe "Candidacy" do
  let(:organization) { create(:organization) }
  let(:state) { :open }
  let(:base_candidacy) do
    create(:candidacy, organization:, state:)
  end

  before do
    switch_to_host(organization.host)
  end

  context "when the candidacy does not exist" do
    it_behaves_like "a 404 page" do
      let(:target_path) { decidim_candidacies.candidacy_path(99_999_999) }
    end
  end

  describe "candidacy page" do
    let!(:candidacy) { base_candidacy }
    let(:attached_to) { candidacy }

    before do
      allow(Decidim::SignatureCollection).to receive(:print_enabled).and_return(true)
    end

    it_behaves_like "editable content for admins" do
      let(:target_path) { decidim_candidacies.candidacy_path(candidacy) }
    end

    context "when requesting the candidacy path" do
      before do
        visit decidim_candidacies.candidacy_path(candidacy)
      end

      shared_examples_for "candidacy shows signatures" do
        it "shows signatures for the state" do
          within ".progress-bar__number" do
            expect(page).to have_css("span", count: 2)
          end
        end
      end

      shared_examples_for "candidacy does not show signatures" do
        it "does not show signatures for the state" do
          expect(page).to have_no_css(".progress-bar__container")
        end
      end

      it "shows the details of the given candidacy" do
        within "[data-content]" do
          expect(page).to have_content(translated(candidacy.title, locale: :en))
          expect(page).to have_content(ActionView::Base.full_sanitizer.sanitize(translated(candidacy.description, locale: :en), tags: []))
          expect(page).to have_content(translated(candidacy.type.title, locale: :en))
          expect(page).to have_content(translated(candidacy.scope.name, locale: :en))
          expect(page).to have_content(candidacy.reference)
        end
      end

      context "when signature interval is defined" do
        let(:base_candidacy) do
          create(:candidacy,
                 organization:,
                 signature_start_date: 1.day.ago,
                 signature_end_date: 1.day.from_now,
                 state:)
        end

        it "displays collection period" do
          within ".candidacies__card__grid-metadata-dates" do
            expect(page).to have_content(1.day.ago.strftime("%d %b"))
            expect(page).to have_content(1.day.from_now.strftime("%d %b"))
          end
        end
      end

      context "when candidacy type has minimum signing age" do
        let(:base_candidacy) do
          create(:candidacy,
                 organization:,
                 state:,
                 scoped_type:)
        end

        let(:scoped_type) do
          create(:candidacies_type_scope,
                 type: create(:candidacies_type,
                              organization:,
                              minimum_signing_age: 16))
        end

        it "displays minimum signing age" do
          within ".candidacy__aside" do
            expect(page).to have_content("Minimum age for signature")
            expect(page).to have_content("16")
          end
        end
      end

      context "when candidacy type has no minimum signing age" do
        let(:base_candidacy) do
          create(:candidacy,
                 organization:,
                 state:,
                 scoped_type:)
        end

        let(:scoped_type) do
          create(:candidacies_type_scope,
                 type: create(:candidacies_type,
                              organization:,
                              minimum_signing_age: nil))
        end

        it "does not display minimum signing age section" do
          within ".candidacy__aside" do
            expect(page).to have_no_content("Minimum signing age")
          end
        end
      end

      it_behaves_like "candidacy shows signatures"

      context "when candidacy state is rejected" do
        let(:state) { :rejected }

        it_behaves_like "candidacy shows signatures"
      end

      context "when candidacy state is accepted" do
        let(:state) { :accepted }

        it_behaves_like "candidacy shows signatures"
      end

      context "when candidacy state is created" do
        let(:state) { :created }

        it_behaves_like "candidacy does not show signatures"
      end

      context "when candidacy state is validating" do
        let(:state) { :validating }

        it_behaves_like "candidacy does not show signatures"
      end

      context "when candidacy state is discarded" do
        let(:state) { :discarded }

        it_behaves_like "candidacy does not show signatures"
      end

      # Candidacies only show the documents tab (images were removed in #7).
      context "when it has attachments" do
        let!(:document) { create(:attachment, :with_pdf, attached_to:) }
        let!(:link) { create(:attachment, :with_link, attached_to:) }
        let!(:image) { create(:attachment, attached_to:) }

        before { visit current_path }

        it "shows the documents" do
          find("li [data-controls='panel-documents']").click
          within "#panel-documents" do
            expect(page).to have_content(translated(document.title))
            expect(page).to have_content(translated(link.title))
          end
          expect(page).to have_no_css("li [data-controls='panel-images']")
        end
      end

      context "when documents are ordered by weight" do
        let!(:last_document) { create(:attachment, :with_link, attached_to:, weight: 2) }
        let!(:first_document) { create(:attachment, :with_pdf, attached_to:, weight: 1) }

        before { visit current_path }

        it "shows them ordered" do
          find("li [data-controls='panel-documents']").click
          within "#panel-documents" do
            expect(decidim_escape_translated(first_document.title).gsub("&quot;", "\"")).to appear_before(decidim_escape_translated(last_document.title).gsub("&quot;", "\""))
          end
        end
      end

      context "when the candidacy is not published" do
        let(:state) { :created }

        before do
          candidacy.update!(published_at: nil)
        end

        it "does not display comments section" do
          expect(page).to have_no_css(".comments")
          expect(page).to have_no_content("0 comments")
        end
      end

      context "when the candidacy is published" do
        it "displays comments section" do
          expect(page).to have_css(".comments")
          expect(page).to have_content("0 comments")
        end
      end

      context "when comments are disabled" do
        let(:base_candidacy) do
          create(:candidacy, organization:, state:, scoped_type:)
        end

        let(:scoped_type) do
          create(:candidacies_type_scope,
                 type: create(:candidacies_type,
                              :with_comments_disabled,
                              organization:,
                              signature_type: "online"))
        end

        it "does not have comments" do
          expect(page).to have_no_css(".comments")
          expect(page).to have_no_content("0 comments")
        end
      end
    end

    context "when I am the author of the candidacy" do
      before do
        sign_in candidacy.author
        visit decidim_candidacies.candidacy_path(candidacy)
      end

      shared_examples_for "candidacy does not show send to technical validation" do
        it { expect(page).to have_no_link("Send to technical validation") }
      end

      context "when candidacy state is created" do
        let(:state) { :created }

        context "when the user cannot send the candidacy to technical validation" do
          before do
            candidacy.update!(published_at: nil)
            candidacy.type.update!(minimum_committee_members: 2)
            candidacy.committee_members.destroy_all
            visit decidim_candidacies.candidacy_path(candidacy)
          end

          it_behaves_like "candidacy does not show send to technical validation"
          it { expect(page).to have_content("Before sending your candidacy for technical validation") }
          it { expect(page).to have_link("Edit") }
        end

        context "when the user can send the candidacy to technical validation" do
          before do
            candidacy.update!(published_at: nil)
            visit decidim_candidacies.candidacy_path(candidacy)
          end

          it { expect(page).to have_link("Send to technical validation", href: decidim_candidacies.send_to_technical_validation_candidacy_path(candidacy)) }
          it { expect(page).to have_content('If everything looks ok, click on "Send to technical validation" for an administrator to review and publish your candidacy') }
        end
      end

      context "when candidacy state is validating" do
        let(:state) { :validating }

        it { expect(page).to have_no_link("Edit") }

        it_behaves_like "candidacy does not show send to technical validation"
      end

      context "when candidacy state is discarded" do
        let(:state) { :discarded }

        it_behaves_like "candidacy does not show send to technical validation"
      end

      context "when candidacy state is open" do
        let(:state) { :open }

        it_behaves_like "candidacy does not show send to technical validation"
      end

      context "when candidacy state is rejected" do
        let(:state) { :rejected }

        it_behaves_like "candidacy does not show send to technical validation"
      end

      context "when candidacy state is accepted" do
        let(:state) { :accepted }

        it_behaves_like "candidacy does not show send to technical validation"
      end
    end
  end

  it_behaves_like "followable space content for users" do
    let(:candidacy) { base_candidacy }
    let!(:user) { create(:user, :confirmed, organization:) }
    let(:followable) { candidacy }
    let(:followable_path) { decidim_candidacies.candidacy_path(candidacy) }
  end

  describe "candidacy components" do
    let!(:candidacy) { base_candidacy }
    let!(:meetings_component) { create(:component, :published, participatory_space: candidacy, manifest_name: :meetings) }
    let!(:proposals_component) { create(:component, :unpublished, participatory_space: candidacy, manifest_name: :proposals) }
    let!(:blogs_component) { create(:component, :published, participatory_space: candidacy, manifest_name: :blogs) }

    before do
      create_list(:meeting, 3, :published, component: meetings_component)
      allow(Decidim).to receive(:component_manifests).and_return([meetings_component.manifest, proposals_component.manifest, blogs_component.manifest])
    end

    # The candidacy page does not show the components menu (custom candidacy_head layout since #5),
    # so the components are visited directly.
    context "when visiting a published component" do
      it "shows its content" do
        visit Decidim::EngineRouter.main_proxy(meetings_component).root_path

        expect(page).to have_css('[id^="meetings__meeting"]', count: 3)
      end
    end

    context "when signed in as the author of the candidacy",
            skip: "decidim-blogs and decidim-meetings only grant author permissions for Decidim::Initiative spaces" do
      before do
        sign_in candidacy.author
      end

      it "has special permissions to create posts" do
        visit Decidim::EngineRouter.main_proxy(blogs_component).root_path

        expect(page).to have_content("New post")
      end

      it "has special permissions to create meetings" do
        visit Decidim::EngineRouter.main_proxy(meetings_component).root_path

        expect(page).to have_content("New meeting")
      end
    end
  end
end
