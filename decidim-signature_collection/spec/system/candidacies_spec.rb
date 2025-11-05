# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/has_contextual_help"

describe "Candidacies" do
  let(:organization) { create(:organization) }
  let(:base_candidacy) do
    create(:candidacy, organization:)
  end
  let!(:menu_content_block) { create(:content_block, organization:, manifest_name: :global_menu, scope_name: :homepage) }

  before do
    switch_to_host(organization.host)
  end

  context "when candidacy types and scopes have not been created" do
    it "does not show the menu link" do
      visit decidim.root_path

      within "#home__menu" do
        expect(page).to have_no_content("Candidacies")
      end
    end

    it "does not let access to the candidacies" do
      visit decidim_candidacies.candidacies_path

      expect(page).to have_current_path(decidim.root_path)
      expect(page).to have_content("Candidacies are not yet configured by an administrator")
    end
  end

  context "when candidacy types and scopes have been created" do
    let(:base_candidacy) do
      create(:candidacy, organization:)
    end

    it "shows the menu link" do
      type = create(:candidacies_type, organization:)
      create(:candidacies_type_scope, type:)

      visit decidim.root_path

      within "#home__menu" do
        expect(page).to have_content("Candidacies")
      end
    end

    context "when there are some published candidacies" do
      let!(:candidacy) { base_candidacy }
      let!(:unpublished_candidacy) do
        create(:candidacy, :created, organization:)
      end

      before do
        allow(Decidim::SignatureCollection).to receive(:print_enabled).and_return(true)
      end

      it_behaves_like "shows contextual help" do
        let(:index_path) { decidim_candidacies.candidacies_path }
        let(:manifest_name) { :candidacies }
      end

      it_behaves_like "editable content for admins" do
        let(:target_path) { decidim_candidacies.candidacies_path }
      end

      context "when requesting the candidacies path" do
        before do
          visit decidim_candidacies.candidacies_path
        end

        it "lists all the candidacies" do
          within "#candidacies" do
            expect(page).to have_content("1")
            expect(page).to have_content(translated(candidacy.title, locale: :en))
            expect(page).to have_no_content(translated(unpublished_candidacy.title, locale: :en))
          end
        end

        it "links to the individual candidacy page" do
          click_on(translated(candidacy.title, locale: :en))
          expect(page).to have_current_path(decidim_candidacies.candidacy_path(candidacy))
        end

        it "displays the filter candidacy type filter" do
          within ".new_filter[action$='/candidacies']" do
            expect(page).to have_content(/Type/i)
          end
        end

        context "when there is a unique candidacy type" do
          let!(:unpublished_candidacy) { nil }

          it "does not display the candidacy type filter" do
            within ".new_filter[action$='/candidacies']" do
              expect(page).to have_no_content(/Type/i)
            end
          end
        end

        context "when there are only closed candidacies" do
          let!(:closed_candidacy) do
            create(:candidacy, :discarded, organization:)
          end
          let(:base_candidacy) { nil }

          before do
            visit decidim_candidacies.candidacies_path
          end

          it "displays a warning" do
            expect(page).to have_content("Currently, there are no open candidacies, but here you can find all the closed candidacies listed.")
          end

          it "shows closed candidacies" do
            within "#candidacies" do
              expect(page).to have_content(translated(closed_candidacy.title, locale: :en))
            end
          end
        end
      end

      context "when requesting the candidacies path and candidacies have attachments but the file is not present" do
        let!(:base_candidacy) { create(:candidacy, :with_photos, organization:) }

        before do
          candidacy.attachments.each do |attachment|
            attachment.file.purge
          end
          visit decidim_candidacies.candidacies_path
        end

        it "lists all the candidacies without errors" do
          within "#candidacies" do
            expect(page).to have_content("1")
            expect(page).to have_content(translated(candidacy.title, locale: :en))
            expect(page).to have_no_content(translated(unpublished_candidacy.title, locale: :en))
          end
        end
      end

      context "when it is an candidacy with card image enabled" do
        before do
          candidacy.type.attachments_enabled = true
          candidacy.type.save!

          create(:attachment, attached_to: candidacy)

          visit decidim_candidacies.candidacies_path
        end

        it "shows the card image" do
          within "#candidacy_#{candidacy.id}" do
            expect(page).to have_css(".card__grid-img")
          end
        end
      end
    end

    context "when there are more than 20 candidacies" do
      before do
        create_list(:candidacy, 21, organization:)
        visit decidim_candidacies.candidacies_path
      end

      it "shows the correct candidacies count" do
        expect(page).to have_content("21")
      end
    end
  end
end
