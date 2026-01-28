# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

module ValidSignador
  RSpec.describe Request do
    let(:config) do
      instance_double(
        Configuration,
        domain: "https://example.cat",
        api_key: "test_api_key",
        base_url: "https://signador-pre.aoc.cat/signador"
      )
    end

    subject(:request) { described_class.new(config) }

    before do
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    after do
      WebMock.reset!
    end

    describe "#get" do
      let(:path) { "/initProcess" }
      let(:url) { "https://signador-pre.aoc.cat/signador/initProcess" }

      context "when request is successful" do
        let(:response_body) { { "status" => "OK", "token" => "test-token-123" }.to_json }

        before do
          stub_request(:get, url)
            .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
        end

        it "returns parsed JSON response" do
          result = request.get(path)

          expect(result).to eq({ "status" => "OK", "token" => "test-token-123" })
        end

        it "includes authentication headers" do
          request.get(path)

          expect(WebMock).to have_requested(:get, url)
            .with(headers: { "Authorization" => /^SC .+/, "Origin" => "https://example.cat", "Date" => /.+/ })
        end
      end

      context "when authentication fails" do
        before do
          stub_request(:get, url)
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect { request.get(path) }.to raise_error(AuthenticationError, /Authentication failed/)
        end
      end

      context "when response is not valid JSON" do
        before do
          stub_request(:get, url)
            .to_return(status: 200, body: "Invalid JSON")
        end

        it "raises InvalidResponseError" do
          expect { request.get(path) }.to raise_error(InvalidResponseError, /Invalid JSON response/)
        end
      end

      context "when server returns error" do
        before do
          stub_request(:get, url)
            .to_return(status: 500, body: "Internal Server Error")
        end

        it "raises ApiError" do
          expect { request.get(path) }.to raise_error(ApiError, /Server error/)
        end
      end
    end

    describe "#post" do
      let(:path) { "/startSignProcess" }
      let(:url) { "https://signador-pre.aoc.cat/signador/startSignProcess" }
      let(:payload) { { token: "test-token", document: "base64-encoded-doc" } }

      context "when request is successful" do
        let(:response_body) { { "status" => "OK", "token" => "test-token" }.to_json }

        before do
          stub_request(:post, url)
            .with(body: payload.to_json)
            .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
        end

        it "returns parsed JSON response" do
          result = request.post(path, payload)

          expect(result).to eq({ "status" => "OK", "token" => "test-token" })
        end

        it "includes correct headers" do
          request.post(path, payload)

          expect(WebMock).to have_requested(:post, url)
            .with(
              headers: {
                "Content-Type" => "application/json",
                "Origin" => "https://example.cat"
              },
              body: payload.to_json
            )
        end
      end

      context "when client error occurs" do
        before do
          stub_request(:post, url)
            .to_return(status: 400, body: "Bad Request")
        end

        it "raises ApiError" do
          expect { request.post(path, payload) }.to raise_error(ApiError, /Client error/)
        end
      end
    end

    describe "#hmac_signature" do
      it "generates valid HMAC signature" do
        date = "17/12/2025 10:30"
        data = "#{config.domain}_#{date}"

        expected_digest = OpenSSL::HMAC.digest("SHA256", config.api_key, data)
        expected_signature = Base64.strict_encode64(expected_digest)

        # Access private method for testing
        signature = request.send(:hmac_signature, date)

        expect(signature).to eq(expected_signature)
      end
    end
  end
end
