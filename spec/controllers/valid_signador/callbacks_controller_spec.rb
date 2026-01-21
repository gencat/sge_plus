# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidSignador::CallbacksController do
  describe "POST #create" do
    let(:token) { "test-token-123" }
    let(:signed_result) { Base64.strict_encode64("<xml>Signed document</xml>") }

    context "when process state exists in session" do
      let(:process_state) do
        {
          token: token,
          candidacy_id: 1,
          document_original: "<xml>Original</xml>",
          timestamp_inici: Time.current.iso8601,
          user_id: 2,
          redirect_url: "/candidacies/1"
        }
      end

      before do
        session[:valid_signador_process] = process_state
      end

      context "with successful signature" do
        let(:params) do
          {
            token: token,
            status: "OK",
            signResult: signed_result
          }
        end

        it "processes the signed document" do
          post :create, params: params

          expect(response).to redirect_to("/candidacies/1")
          expect(flash[:notice]).to eq("Document signat correctament")
        end

        it "clears the process state from session" do
          post :create, params: params

          expect(session[:valid_signador_process]).to be_nil
        end
      end

      context "with signature error" do
        let(:params) do
          {
            token: token,
            status: "KO",
            error: "User cancelled signature"
          }
        end

        it "redirects with error message" do
          post :create, params: params

          expect(response).to redirect_to("/candidacies/1")
          expect(flash[:alert]).to include("User cancelled signature")
        end

        it "clears the process state from session" do
          post :create, params: params

          expect(session[:valid_signador_process]).to be_nil
        end
      end

      context "with mismatched token" do
        let(:params) do
          {
            token: "different-token",
            status: "OK",
            signResult: signed_result
          }
        end

        it "returns error" do
          post :create, params: params, format: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["error"]).to include("token no coincideix")
        end
      end

      context "without signed result" do
        let(:params) do
          {
            token: token,
            status: "OK"
          }
        end

        it "returns error" do
          post :create, params: params, format: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["error"]).to include("No s'ha rebut el document signat")
        end
      end
    end

    context "when no process state exists in session" do
      let(:params) do
        {
          token: token,
          status: "OK",
          signResult: signed_result
        }
      end

      it "returns not found error" do
        post :create, params: params, format: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to include("No s'ha trobat l'estat del procés")
      end
    end
  end
end
