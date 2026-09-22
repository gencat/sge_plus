# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::CandidaciesController, skip: "Awaiting review" do
  routes { Decidim::SignatureCollection::Engine.routes }

  let(:organization) { create(:organization) }
  let!(:candidacy) { create(:candidacy, organization:) }
  let!(:created_candidacy) { create(:candidacy, :created, organization:) }

  before do
    request.env["decidim.current_organization"] = organization
  end

  describe "GET index" do
    it "Only returns published candidacies" do
      get :index
      expect(subject.helpers.candidacies).to include(candidacy)
      expect(subject.helpers.candidacies).not_to include(created_candidacy)
    end

    context "when no order is given" do
      let(:voted_candidacy) { create(:candidacy, organization:) }
      let!(:vote) { create(:candidacy_user_vote, candidacy: voted_candidacy) }
      let!(:candidacies_settings) { create(:candidacies_settings, :most_signed) }

      it "return in the default order" do
        get :index, params: { order: "most_voted" }

        expect(subject.helpers.candidacies.first).to eq(voted_candidacy)
      end
    end

    context "when order by most_voted" do
      let(:voted_candidacy) { create(:candidacy, organization:) }
      let!(:vote) { create(:candidacy_user_vote, candidacy: voted_candidacy) }

      it "most voted appears first" do
        get :index, params: { order: "most_voted" }

        expect(subject.helpers.candidacies.first).to eq(voted_candidacy)
      end
    end

    context "when order by most recent" do
      let!(:old_candidacy) { create(:candidacy, organization:, created_at: candidacy.created_at - 12.months) }

      it "most recent appears first" do
        get :index, params: { order: "recent" }
        expect(subject.helpers.candidacies.first).to eq(candidacy)
      end
    end

    context "when order by most recently published" do
      let!(:old_candidacy) { create(:candidacy, organization:, published_at: candidacy.published_at - 12.months) }

      it "most recent appears first" do
        get :index, params: { order: "recently_published" }
        expect(subject.helpers.candidacies.first).to eq(candidacy)
      end
    end

    context "when order by most commented" do
      let(:commented_candidacy) { create(:candidacy, organization:) }
      let!(:comment) { create(:comment, commentable: commented_candidacy) }

      it "most commented appears first" do
        get :index, params: { order: "most_commented" }
        expect(subject.helpers.candidacies.first).to eq(commented_candidacy)
      end
    end
  end

  describe "GET show" do
    context "and any user" do
      it "Shows published candidacies" do
        get :show, params: { slug: candidacy.slug }
        expect(subject.helpers.current_candidacy).to eq(candidacy)
      end

      it "Returns 404 when there is not an candidacy" do
        expect { get :show, params: { slug: "invalid-candidacy" } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it "Throws exception on non published candidacies" do
        get :show, params: { slug: created_candidacy.slug }
        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:found)
      end
    end

    context "and candidacy Owner" do
      before do
        sign_in created_candidacy.author, scope: :user
      end

      it "Unpublished candidacies are shown too" do
        get :show, params: { slug: created_candidacy.slug }
        expect(subject.helpers.current_candidacy).to eq(created_candidacy)
      end
    end
  end

  describe "Edit candidacy as promoter" do
    include ActionView::Helpers::TextHelper

    before do
      sign_in created_candidacy.author, scope: :user
    end

    let(:valid_attributes) do
      attrs = attributes_for(:candidacy, organization:)
      attrs[:title] = truncate(translated(attrs[:title]), length: 150, omission: "")
      attrs[:description] = Decidim::HtmlTruncation.new(translated(attrs[:description]), max_length: 150, tail: "").perform
      attrs[:signature_end_date] = I18n.l(attrs[:signature_end_date], format: :decidim_short)
      attrs[:signature_start_date] = I18n.l(attrs[:signature_start_date], format: :decidim_short)
      attrs[:type_id] = created_candidacy.type.id
      attrs
    end

    it "edit when user is allowed" do
      get :edit, params: { slug: created_candidacy.slug }
      expect(flash[:alert]).to be_nil
      expect(response).to have_http_status(:ok)
    end

    context "and update an candidacy" do
      it "are allowed" do
        put :update,
            params: {
              slug: created_candidacy.to_param,
              candidacy: valid_attributes
            }
        expect(flash[:alert]).to be_nil
        expect(response).to have_http_status(:found)
      end
    end

    context "when candidacy is invalid" do
      it "does not update when title is nil" do
        invalid_attributes = valid_attributes.merge(title: nil)

        put :update,
            params: {
              slug: created_candidacy.to_param,
              candidacy: invalid_attributes
            }

        expect(flash[:alert]).not_to be_empty
        expect(response).to have_http_status(:ok)
      end

      context "when the existing candidacy has attachments and there are other errors on the form" do
        let!(:created_candidacy) do
          create(
            :candidacy,
            :created,
            :with_documents,
            organization:
          )
        end

        include_context "with controller rendering the view" do
          let(:invalid_attributes) do
            valid_attributes.merge(
              title: nil,
              documents: created_candidacy.documents.map { |a| a.id.to_s }
            )
          end

          it "displays the editing form with errors" do
            put :update, params: {
              slug: created_candidacy.to_param,
              candidacy: invalid_attributes
            }

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:edit)
            expect(response.body).to include("There was a problem updating the candidacy.")
          end
        end
      end
    end
  end
end
