# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

module ValidSignador
  RSpec.describe Client do
    let(:session) { {} }

    subject(:client) { described_class.new(session: session) }

    before do
      ENV["SIGNADOR_DOMAIN"] = "https://example.cat"
      ENV["SIGNADOR_API_KEY"] = "test_api_key"
      ENV["SIGNADOR_BASE_URL"] = "https://signador-pre.aoc.cat"
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    after do
      ENV.delete("SIGNADOR_DOMAIN")
      ENV.delete("SIGNADOR_API_KEY")
      ENV.delete("SIGNADOR_BASE_URL")
      WebMock.reset!
    end

    describe "#init_process" do
      let(:url) { "https://signador-pre.aoc.cat/signador/initProcess" }

      context "when successful" do
        let(:response_body) { { "status" => "OK", "token" => "test-token-123" }.to_json }

        before do
          stub_request(:get, url)
            .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
        end

        it "returns the response with token" do
          result = client.init_process

          expect(result).to eq({ "status" => "OK", "token" => "test-token-123" })
        end
      end

      context "when API returns error status" do
        let(:response_body) { { "status" => "KO", "message" => "Invalid credentials" }.to_json }

        before do
          stub_request(:get, url)
            .to_return(status: 400, body: response_body, headers: { "Content-Type" => "application/json" })
        end

        it "raises ApiError" do
          expect { client.init_process }.to raise_error(ApiError, /Invalid credentials/)
        end
      end
    end

    describe "#start_sign_process" do
      let(:url) { "https://signador-pre.aoc.cat/signador/startSignProcess" }
      let(:token) { "test-token-123" }
      let(:document) { "<xml>Test</xml>" }
      let(:options) { { candidacy_id: 1, user_id: 2, final_redirect_url: "/success" } }

      context "when successful" do
        let(:response_body) { { "status" => "OK", "token" => token }.to_json }

        before do
          stub_request(:post, url)
            .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
        end

        it "returns the response" do
          result = client.start_sign_process(token: token, document: document, options: options)

          expect(result).to eq({ "status" => "OK", "token" => token })
        end

        it "stores process state in session" do
          client.start_sign_process(token: token, document: document, options: options)

          expect(session[:valid_signador_process]).to include(
            token: token,
            document_original: document,
            candidacy_id: 1,
            user_id: 2,
            redirect_url: "/success"
          )
          expect(session[:valid_signador_process][:timestamp_inici]).to be_present
        end
      end
    end

    describe "#get_signature" do
      let(:token) { "test-token-123" }
      let(:url) { "https://signador-pre.aoc.cat/signador/getSignature?identificador=#{token}" }

      context "when successful" do
        let(:signed_doc) { Base64.strict_encode64("<xml>Signed</xml>") }
        let(:response_body) do
          {
            "status" => "OK",
            "token" => token,
            "signResult" => signed_doc,
            "type" => "XML"
          }.to_json
        end

        before do
          stub_request(:get, url)
            .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
        end

        it "returns the signed document" do
          result = client.get_signature(token: token)

          expect(result).to include("status" => "OK", "signResult" => signed_doc)
        end
      end
    end

    describe "#sign_url" do
      let(:token) { "test-token-123" }

      it "returns the correct signing URL" do
        url = client.sign_url(token: token)

        expect(url).to eq("https://signador-pre.aoc.cat/signador/?id=test-token-123")
      end
    end

    describe "#process_state" do
      context "when state exists in session" do
        let(:state) { { token: "test-token", user_id: 1 } }

        before do
          session[:valid_signador_process] = state
        end

        it "returns the stored state" do
          expect(client.process_state).to eq(state)
        end
      end

      context "when no state exists" do
        it "returns nil" do
          expect(client.process_state).to be_nil
        end
      end
    end

    describe "#clear_process_state!" do
      before do
        session[:valid_signador_process] = { token: "test-token" }
      end

      it "removes the state from session" do
        client.clear_process_state!

        expect(session[:valid_signador_process]).to be_nil
      end
    end
  end
end
