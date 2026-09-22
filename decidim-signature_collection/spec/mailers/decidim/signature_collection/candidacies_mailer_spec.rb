# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesMailer, skip: "Awaiting review" do
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

      context "when notifies admins validation" do
        let!(:admin1) { create(:user, :admin, organization:, email: "admin1@example.org") }
        let!(:admin2) { create(:user, :admin, organization:, email: "admin2@example.org") }
        let(:admins) { [admin1, admin2] }
        let(:mail) { described_class.notify_admins_validation(candidacy, admins) }

        it "renders the headers with candidacy title" do
          expect(mail.subject).to eq("You have a new candidacy to review: '#{translated(candidacy.title)}'")
        end

        it "sends to all admin emails" do
          expect(mail.to).to contain_exactly(admin1.email, admin2.email)
        end

        it "renders the body with candidacy title" do
          expect(mail.body.encoded).to include(decidim_sanitize_translated(candidacy.title))
        end

        it "includes the validation instruction message" do
          expect(mail.body.encoded).to include("Please review the candidacy and make the necessary technical validation")
        end

        it "includes a link to the candidacy" do
          candidacy_url = router.candidacy_url(candidacy, host: organization.host)
          expect(mail.body.encoded).to include(candidacy_url)
        end

        context "when admins is empty" do
          let(:admins) { [] }

          it "does not send the email" do
            expect(mail.message).to be_a(ActionMailer::Base::NullMail)
          end
        end

        context "when admins is nil" do
          let(:admins) { nil }

          it "does not send the email" do
            expect(mail.message).to be_a(ActionMailer::Base::NullMail)
          end
        end
      end

      context "when notifies members candidacy answered" do
        let(:candidacy) { create(:candidacy, :answered, organization:) }
        let(:current_user) { create(:user, :admin, organization:) }
        let!(:admin1) { create(:user, :admin, organization:, email: "admin1@example.org") }
        let!(:committee_member) { create(:user, organization:, email: "member@example.org") }
        let(:members) { [admin1, committee_member, candidacy.author] }
        let(:mail) { described_class.notify_members_candidacy_answered(candidacy, current_user, members) }

        it "renders the headers with candidacy title" do
          expect(mail.subject).to eq("The candidacy '#{translated(candidacy.title)}' has been answered")
        end

        it "sends to all member emails" do
          expect(mail.to).to contain_exactly(admin1.email, committee_member.email, candidacy.author.email)
        end

        it "renders the body with candidacy title" do
          expect(mail.body.encoded).to include(decidim_sanitize_translated(candidacy.title))
        end

        it "includes the answered body message" do
          expect(mail.body.encoded).to include("A response has been published for the candidacy")
        end

        it "includes the candidacy answer" do
          expect(mail.body.encoded).to include(decidim_sanitize_translated(candidacy.answer))
        end

        it "includes a link to the candidacy" do
          candidacy_url = router.candidacy_url(candidacy, host: organization.host)
          expect(mail.body.encoded).to include(candidacy_url)
        end

        context "when members is empty" do
          let(:members) { [] }

          it "does not send the email" do
            expect(mail.message).to be_a(ActionMailer::Base::NullMail)
          end
        end

        context "when members is nil" do
          let(:members) { nil }

          it "does not send the email" do
            expect(mail.message).to be_a(ActionMailer::Base::NullMail)
          end
        end

        context "when a member has no email" do
          let(:user_without_email) { create(:user, organization:, email: nil) }
          let(:members) { [admin1, user_without_email] }

          it "sends only to members with email" do
            expect(mail.to).to contain_exactly(admin1.email)
          end
        end
      end
    end
  end
end
