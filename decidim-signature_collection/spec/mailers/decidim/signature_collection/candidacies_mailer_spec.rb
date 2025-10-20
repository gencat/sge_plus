# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesMailer do
      include Decidim::TranslationsHelper

      let(:organization) { create(:organization, host: "1.lvh.me") }
      let(:candidacy) { create(:candidacy, organization:) }
      let(:router) { Decidim::SignatureCollection::Engine.routes.url_helpers }
      let(:admin_router) { Decidim::SignatureCollection::AdminEngine.routes.url_helpers }

      context "when notifies creation" do
        let(:mail) { described_class.notify_creation(candidacy) }

        context "when the promoting committee is enabled" do
          it "renders the headers" do
            expect(mail.subject).to eq("Your candidacy '#{translated(candidacy.title)}' has been created")
            expect(mail.to).to eq([candidacy.author.email])
          end

          it "renders the body" do
            expect(mail.body.encoded).to include(decidim_escape_translated(candidacy.title))
          end

          it "renders the promoter committee help" do
            expect(mail.body).to match("Forward the following link to invite people to the promoter committee")
          end
        end

        context "when the promoting committee is disabled" do
          let(:organization) { create(:organization) }
          let(:candidacies_type) { create(:candidacies_type, organization:, promoting_committee_enabled: false) }
          let(:scoped_type) { create(:candidacies_type_scope, type: candidacies_type) }
          let(:candidacy) { create(:candidacy, organization:, scoped_type:) }

          it "renders the headers" do
            expect(mail.subject).to eq("Your candidacy '#{translated(candidacy.title)}' has been created")
            expect(mail.to).to eq([candidacy.author.email])
          end

          it "renders the body" do
            expect(mail.body.encoded).to include(decidim_html_escape(translated(candidacy.title)))
          end

          it "does not render the promoter committee help" do
            expect(mail.body).not_to match("Forward the following link to invite people to the promoter committee")
          end
        end

        it "renders the correct link" do
          expect(mail).to have_link(router.candidacy_url(candidacy, host: candidacy.organization.host))
          expect(mail).to have_no_link(admin_router.candidacy_url(candidacy, host: candidacy.organization.host))
        end
      end

      context "when notifies state change" do
        let(:mail) { described_class.notify_state_change(candidacy, candidacy.author) }

        it "renders the headers" do
          expect(mail.subject).to eq("The candidacy #{translated(candidacy.title)} has changed its status")
          expect(mail.to).to eq([candidacy.author.email])
        end

        it "renders the body" do
          expect(mail.body).to include("The candidacy #{decidim_sanitize_translated(candidacy.title)} has changed its status to: #{I18n.t(candidacy.state, scope: "decidim.signature_collection.admin_states")}")
        end
      end

      context "when notifies progress" do
        let(:mail) { described_class.notify_progress(candidacy, candidacy.author) }

        it "renders the headers" do
          expect(mail.subject).to eq("Summary about the candidacy: #{translated(candidacy.title)}")
          expect(mail.to).to eq([candidacy.author.email])
        end

        it "renders the body" do
          expect(mail.body.encoded).to include(decidim_sanitize_translated(candidacy.title))
        end
      end
    end
  end
end
