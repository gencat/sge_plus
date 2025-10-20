# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CommitteeRequestsController do
      routes { Decidim::SignatureCollection::Engine.routes }

      let(:organization) { create(:organization) }
      let!(:candidacy) { create(:candidacy, :created, organization:) }
      let(:admin_user) { create(:user, :admin, :confirmed, organization:) }
      let(:user) { create(:user, :confirmed, organization:) }

      before do
        request.env["decidim.current_organization"] = organization
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      context "when GET spawn" do
        let(:user) { create(:user, :confirmed, organization:) }

        before do
          create(:authorization, user:)
          sign_in user, scope: :user
        end

        context "and created candidacy" do
          it "Membership request is created" do
            expect do
              get :spawn, params: { candidacy_slug: candidacy.slug }
            end.to change(CandidaciesCommitteeMember, :count).by(1)
          end

          it "Duplicated requests finish with an error" do
            expect do
              get :spawn, params: { candidacy_slug: candidacy.slug }
            end.to change(CandidaciesCommitteeMember, :count).by(1)

            expect do
              get :spawn, params: { candidacy_slug: candidacy.slug }
            end.not_to change(CandidaciesCommitteeMember, :count)
          end
        end

        context "and published candidacy" do
          let!(:published_candidacy) { create(:candidacy, organization:) }

          it "Membership request is not created" do
            expect do
              get :spawn, params: { candidacy_slug: published_candidacy.slug }
            end.not_to change(CandidaciesCommitteeMember, :count)
          end
        end
      end

      context "when GET approve" do
        let(:membership_request) { create(:candidacies_committee_member, candidacy:, state: "requested") }

        context "and Owner" do
          before do
            sign_in candidacy.author, scope: :user
          end

          it "request gets approved" do
            get :approve, params: { candidacy_slug: membership_request.candidacy.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_accepted
          end
        end

        context "and other users" do
          let(:user) { create(:user, :confirmed, organization:) }

          before do
            create(:authorization, user:)
            sign_in user, scope: :user
          end

          it "Action is denied" do
            get :approve, params: { candidacy_slug: membership_request.candidacy.to_param, id: membership_request.to_param }
            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "and Admin" do
          before do
            sign_in admin_user, scope: :user
          end

          it "request gets approved" do
            get :approve, params: { candidacy_slug: membership_request.candidacy.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_accepted
          end
        end
      end

      context "when DELETE revoke" do
        let(:membership_request) { create(:candidacies_committee_member, candidacy:, state: "requested") }

        context "and Owner" do
          before do
            sign_in candidacy.author, scope: :user
          end

          it "request gets approved" do
            delete :revoke, params: { candidacy_slug: membership_request.candidacy.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_rejected
          end
        end

        context "and Other users" do
          let(:user) { create(:user, :confirmed, organization:) }

          before do
            create(:authorization, user:)
            sign_in user, scope: :user
          end

          it "Action is denied" do
            delete :revoke, params: { candidacy_slug: membership_request.candidacy.to_param, id: membership_request.to_param }
            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "and Admin" do
          before do
            sign_in admin_user, scope: :user
          end

          it "request gets approved" do
            delete :revoke, params: { candidacy_slug: membership_request.candidacy.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_rejected
          end
        end
      end
    end
  end
end
