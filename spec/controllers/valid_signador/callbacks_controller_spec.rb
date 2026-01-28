# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidSignador::CallbacksController do
  describe "POST #create" do
    let(:token) { "test-token-123" }
    let(:signed_result) { Base64.strict_encode64("<xml>Signed document</xml>") }
    let!(:vote) { create(:candidacy_user_vote, signador_token: token) }
    let(:client) { instance_double(ValidSignador::Client) }

    before do
      allow(ValidSignador::Client).to receive(:new).and_return(client)
    end

    context "when process state exists in session" do
      let(:process_state) do
        {
          token_id: token,
          candidacy_id: vote.candidacy.id,
          document_original: "<xml>Original</xml>",
          timestamp_inici: Time.current.iso8601,
          redirect_url: "/candidacies/1"
        }
      end

      before do
        session[:valid_signador_process] = process_state
      end

      context "with successful signature" do
        let(:params) do
          {
            token_id: token,
            status: "OK",
            signResult: signed_result
          }
        end

        let(:get_signature_response) do
          {
            "status" => "OK",
            "signResult" => signed_result,
            "type" => "XML"
          }
        end

        before do
          allow(client).to receive(:get_signature).with(token: token).and_return(get_signature_response)
        end

        it "processes the signed document" do
          post :create, params: params

          expect(response).to redirect_to("/candidacies/#{vote.candidacy.slug}/signatures/finish")
        end
      end

      context "with signature error" do
        let(:params) do
          {
            token_id: token,
            status: "KO",
            error: "User cancelled signature"
          }
        end

        let(:get_signature_response) do
          {
            "status" => "KO",
            "message" => "User cancelled signature"
          }
        end

        before do
          allow(client).to receive(:get_signature).with(token: token).and_return(get_signature_response)
        end

        it "redirects with error message" do
          post :create, params: params

          expect(response).to redirect_to("/candidacies/#{vote.candidacy.slug}/signatures/fill_personal_data")
          expect(flash[:alert]).to include("User cancelled signature")
        end
      end

      context "with mismatched token" do
        let(:different_token) { "different-token" }
        let(:params) do
          {
            token_id: different_token,
            status: "OK",
            signResult: signed_result
          }
        end

        it "returns error" do
          post :create, params: params, format: :json

          expect(response).to be_redirect
          expect(flash[:alert]).to be_present
        end
      end

      context "without signed result" do
        let(:params) do
          {
            token_id: token,
            status: "OK"
          }
        end

        let(:get_signature_response) do
          {
            "status" => "OK",
            "type" => "XML"
          }
        end

        before do
          allow(client).to receive(:get_signature).with(token: token).and_return(get_signature_response)
        end

        it "redirects with error" do
          post :create, params: params
          expect(response).to redirect_to("/candidacies/#{vote.candidacy.slug}/signatures/fill_personal_data")
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "when no process state exists in session" do
      let(:params) do
        {
          token_id: token,
          status: "OK",
          signResult: signed_result
        }
      end

      let(:get_signature_response) do
        {
          "status" => "OK",
          "signResult" => signed_result,
          "type" => "XML"
        }
      end

      before do
        allow(client).to receive(:get_signature).with(token: token).and_return(get_signature_response)
      end

      it "processes normally even without session state" do
        post :create, params: params

        expect(response).to be_redirect
      end
    end
  end
end
