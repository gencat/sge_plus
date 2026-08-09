# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::Admin::CandidaciesController do
  routes { Decidim::SignatureCollection::AdminEngine.routes }

  let(:user) { create(:user, :confirmed, :admin_terms_accepted, organization:) }
  let(:admin_user) { create(:user, :admin, :confirmed, organization:) }
  let(:organization) { create(:organization) }
  let!(:candidacy) { create(:candidacy, organization:) }
  let!(:created_candidacy) { create(:candidacy, :created, organization:) }

  before do
    request.env["decidim.current_organization"] = organization
    candidacy.author.update(admin_terms_accepted_at: Time.current)
    candidacy.committee_members.approved.first.user.update(admin_terms_accepted_at: Time.current)
    created_candidacy.author.update(admin_terms_accepted_at: Time.current)
  end

  context "when index" do
    context "and Users without candidacies" do
      before do
        sign_in user, scope: :user
      end

      it "candidacy list is not allowed" do
        get :index
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and anonymous users do" do
      it "candidacy list is not allowed" do
        get :index
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and admin users" do
      before do
        sign_in admin_user, scope: :user
      end

      it "candidacy list is allowed" do
        get :index
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end

    context "and candidacy author" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "candidacy list is allowed" do
        get :index
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end

    describe "and promotal committee members" do
      before do
        sign_in candidacy.committee_members.approved.first.user, scope: :user
      end

      it "candidacy list is allowed" do
        get :index
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when edit" do
    context "and Users without candidacies" do
      before do
        sign_in user, scope: :user
      end

      it "are not allowed" do
        get :edit, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and anonymous users" do
      it "are not allowed" do
        get :edit, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and admin users" do
      before do
        sign_in admin_user, scope: :user
      end

      it "are allowed" do
        get :edit, params: { slug: candidacy.to_param }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end

    context "and candidacy author" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "are allowed" do
        get :edit, params: { slug: candidacy.to_param }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end

    context "and promotal committee members" do
      before do
        sign_in candidacy.committee_members.approved.first.user, scope: :user
      end

      it "are allowed" do
        get :edit, params: { slug: candidacy.to_param }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when update" do
    let(:valid_attributes) do
      attrs = attributes_for(:candidacy, organization:)
      attrs[:signature_end_date] = I18n.l(attrs[:signature_end_date], format: :decidim_short)
      attrs[:signature_start_date] = I18n.l(attrs[:signature_start_date], format: :decidim_short)
      attrs
    end

    context "and Users without candidacies" do
      before do
        sign_in user, scope: :user
      end

      it "are not allowed" do
        put :update,
            params: {
              slug: candidacy.to_param,
              candidacy: valid_attributes
            }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and anonymous users do" do
      it "are not allowed" do
        put :update,
            params: {
              slug: candidacy.to_param,
              candidacy: valid_attributes
            }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and admin users" do
      before do
        sign_in admin_user, scope: :user
      end

      it "are allowed" do
        put :update,
            params: {
              slug: candidacy.to_param,
              candidacy: valid_attributes
            }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:found)
      end
    end

    context "and candidacy author" do
      context "and candidacy published" do
        before do
          sign_in candidacy.author, scope: :user
        end

        it "are not allowed" do
          put :update,
              params: {
                slug: candidacy.to_param,
                candidacy: valid_attributes
              }
          expect(flash[:alert]).not_to be_nil
          expect(response).to have_http_status(:found)
        end
      end

      context "and candidacy created" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        before do
          sign_in candidacy.author, scope: :user
        end

        it "are allowed" do
          put :update,
              params: {
                slug: candidacy.to_param,
                candidacy: valid_attributes
              }
          expect(flash[:alert]).to be_nil
          expect(response).to have_http_status(:found)
        end
      end
    end

    context "and promotal committee members" do
      context "and candidacy published" do
        before do
          sign_in candidacy.committee_members.approved.first.user, scope: :user
        end

        it "are not allowed" do
          put :update,
              params: {
                slug: candidacy.to_param,
                candidacy: valid_attributes
              }
          expect(flash[:alert]).not_to be_nil
          expect(response).to have_http_status(:found)
        end
      end

      context "and candidacy created" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        before do
          sign_in candidacy.committee_members.approved.first.user, scope: :user
        end

        it "are allowed" do
          put :update,
              params: {
                slug: candidacy.to_param,
                candidacy: valid_attributes
              }
          expect(flash[:alert]).to be_nil
          expect(response).to have_http_status(:found)
        end
      end
    end
  end

  context "when GET send_to_technical_validation" do
    context "and Candidacy in created state" do
      context "and has not enough committee members" do
        before do
          created_candidacy.author.confirm
          sign_in created_candidacy.author, scope: :user
        end

        it "does not pass to technical validation phase" do
          created_candidacy.type.update(minimum_committee_members: 4)
          get :send_to_technical_validation, params: { slug: created_candidacy.to_param }

          created_candidacy.reload
          expect(created_candidacy).not_to be_validating
        end

        it "does pass to technical validation phase" do
          created_candidacy.type.update(minimum_committee_members: 3)
          get :send_to_technical_validation, params: { slug: created_candidacy.to_param }

          created_candidacy.reload
          expect(created_candidacy).to be_validating
        end
      end

      context "and User is not the owner of the candidacy" do
        let(:other_user) { create(:user, organization:) }

        before do
          sign_in other_user, scope: :user
        end

        it "Raises an error" do
          get :send_to_technical_validation, params: { slug: created_candidacy.to_param }
          expect(flash[:alert]).not_to be_empty
          expect(response).to have_http_status(:found)
        end
      end

      context "and User is the owner of the candidacy. It is in created state" do
        before do
          created_candidacy.author.confirm
          sign_in created_candidacy.author, scope: :user
        end

        it "Passes to technical validation phase" do
          get :send_to_technical_validation, params: { slug: created_candidacy.to_param }

          created_candidacy.reload
          expect(created_candidacy).to be_validating
        end
      end
    end

    context "and Candidacy in discarded state" do
      let!(:discarded_candidacy) { create(:candidacy, :discarded, organization:) }

      before do
        discarded_candidacy.author.update(admin_terms_accepted_at: Time.current)
        sign_in discarded_candidacy.author, scope: :user
      end

      it "Passes to technical validation phase" do
        get :send_to_technical_validation, params: { slug: discarded_candidacy.to_param }

        discarded_candidacy.reload
        expect(discarded_candidacy).to be_validating
      end
    end

    context "and Candidacy not in created or discarded state (published)" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "Raises an error" do
        get :send_to_technical_validation, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end
  end

  context "when POST publish" do
    let!(:candidacy) { create(:candidacy, :validating, organization:) }

    context "and Candidacy owner" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "Raises an error" do
        post :publish, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and Administrator" do
      let!(:admin) { create(:user, :confirmed, :admin, organization:) }

      before do
        sign_in admin, scope: :user
      end

      it "candidacy gets published" do
        post :publish, params: { slug: candidacy.to_param }
        expect(response).to have_http_status(:found)

        candidacy.reload
        expect(candidacy).to be_published
        expect(candidacy.published_at).not_to be_nil
        expect(candidacy.type.signature_period_start).not_to be_nil
        expect(candidacy.type.signature_period_end).not_to be_nil
      end
    end
  end

  context "when DELETE unpublish" do
    context "and Candidacy owner" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "Raises an error" do
        delete :unpublish, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and Administrator" do
      let(:admin) { create(:user, :confirmed, :admin, organization:) }

      before do
        sign_in admin, scope: :user
      end

      it "candidacy gets unpublished" do
        delete :unpublish, params: { slug: candidacy.to_param }
        expect(response).to have_http_status(:found)

        candidacy.reload
        expect(candidacy).not_to be_published
        expect(candidacy).to be_discarded
        expect(candidacy.published_at).to be_nil
      end
    end
  end

  context "when DELETE discard" do
    let(:candidacy) { create(:candidacy, :validating, organization:) }

    context "and Candidacy owner" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "Raises an error" do
        delete :discard, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and Administrator" do
      let(:admin) { create(:user, :confirmed, :admin, organization:) }

      before do
        sign_in admin, scope: :user
      end

      it "candidacy gets discarded" do
        delete :discard, params: { slug: candidacy.to_param }
        expect(response).to have_http_status(:found)

        candidacy.reload
        expect(candidacy).to be_discarded
        expect(candidacy.published_at).to be_nil
      end
    end
  end

  context "when POST accept" do
    let!(:candidacy) { create(:candidacy, :acceptable, signature_type: "any", organization:) }

    context "and Candidacy owner" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "Raises an error" do
        post :accept, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "when Administrator" do
      let!(:admin) { create(:user, :confirmed, :admin, organization:) }

      before do
        sign_in admin, scope: :user
      end

      it "candidacy gets published" do
        post :accept, params: { slug: candidacy.to_param }
        expect(response).to have_http_status(:found)

        candidacy.reload
        expect(candidacy).to be_accepted
      end
    end
  end

  context "when DELETE reject" do
    let!(:candidacy) { create(:candidacy, :rejectable, signature_type: "any", organization:) }

    context "and Candidacy owner" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "Raises an error" do
        delete :reject, params: { slug: candidacy.to_param }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "when Administrator" do
      let!(:admin) { create(:user, :confirmed, :admin, organization:) }

      before do
        sign_in admin, scope: :user
      end

      it "candidacy gets rejected" do
        delete :reject, params: { slug: candidacy.to_param }
        expect(response).to have_http_status(:found)
        expect(flash[:alert]).to be_nil

        candidacy.reload
        expect(candidacy).to be_rejected
      end
    end
  end

  context "when GET export_votes" do
    let(:candidacy) { create(:candidacy, organization:, signature_type: "any") }

    context "and author" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "is not allowed" do
        get :export_votes, params: { slug: candidacy.to_param, format: :csv }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and promotal committee" do
      before do
        sign_in candidacy.committee_members.approved.first.user, scope: :user
      end

      it "is not allowed" do
        get :export_votes, params: { slug: candidacy.to_param, format: :csv }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and admin user" do
      let!(:vote) { create(:candidacy_user_vote, candidacy:) }

      before do
        sign_in admin_user, scope: :user
      end

      it "is allowed" do
        get :export_votes, params: { slug: candidacy.to_param, format: :csv }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when GET export_pdf_signatures" do
    let(:candidacy) { create(:candidacy, :with_user_extra_fields_collection, organization:) }

    context "and author" do
      before do
        sign_in candidacy.author, scope: :user
      end

      it "is not allowed" do
        get :export_pdf_signatures, params: { slug: candidacy.to_param, format: :pdf }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and admin" do
      before do
        sign_in admin_user, scope: :user
      end

      it "is allowed" do
        get :export_pdf_signatures, params: { slug: candidacy.to_param, format: :pdf }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when GET export" do
    context "and user" do
      before do
        sign_in user, scope: :user
      end

      it "is not allowed" do
        expect(Decidim::SignatureCollection::ExportCandidaciesJob).not_to receive(:perform_later).with(user, "CSV", nil)

        get :export, params: { format: :csv }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and admin" do
      before do
        sign_in admin_user, scope: :user
      end

      it "is allowed" do
        expect(Decidim::SignatureCollection::ExportCandidaciesJob).to receive(:perform_later).with(admin_user, organization, "csv", nil)

        get :export, params: { format: :csv }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:found)
      end

      context "when a collection of ids is passed as a parameter" do
        let!(:candidacies) { create_list(:candidacy, 3, organization:) }
        let(:collection_ids) { candidacies.map(&:id) }

        it "enqueues the job" do
          expect(Decidim::SignatureCollection::ExportCandidaciesJob).to receive(:perform_later).with(admin_user, organization, "csv", collection_ids)

          get :export, params: { format: :csv, collection_ids: }
          expect(flash[:alert]).to be_nil
          expect(response).to have_http_status(:found)
        end
      end
    end
  end
end
