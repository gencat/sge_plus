# frozen_string_literal: true

require "rails_helper"

module ValidSignador
  RSpec.describe PayloadBuilder do
    let(:token) { "test-token-123" }
    let(:document) { "<xml>Test document</xml>" }
    let(:options) { {} }

    subject(:builder) { described_class.new(token: token, document: document, options: options) }

    describe "#build" do
      let(:payload) { builder.build }

      it "builds a valid payload structure" do
        expect(payload).to include(
          :redirectUrl,
          :token,
          :descripcio,
          :responseB64,
          :applet_cfg
        )
      end

      it "sets the token correctly" do
        expect(payload[:token]).to eq(token)
      end

      it "uses default redirect URL" do
        expect(payload[:redirectUrl]).to eq("/valid_signador/callback")
      end

      it "uses default description" do
        expect(payload[:descripcio]).to eq("Signatura de document XML")
      end

      it "sets response in base64 by default" do
        expect(payload[:responseB64]).to eq("true")
      end

      describe "applet_cfg" do
        let(:applet_cfg) { payload[:applet_cfg] }

        it "uses generic keystore type" do
          expect(applet_cfg[:keystore_type]).to eq("0")
        end

        it "uses XAdES-T enveloped signature mode (12)" do
          expect(applet_cfg[:signature_mode]).to eq("12")
        end

        it "uses B64fileContent document type (4)" do
          expect(applet_cfg[:doc_type]).to eq("4")
        end

        it "uses SHA-256 hash algorithm by default" do
          expect(applet_cfg[:hash_algorithm]).to eq("SHA-256")
        end

        it "encodes document in base64" do
          expected_encoded = Base64.strict_encode64(document)
          expect(applet_cfg[:document_to_sign]).to eq(expected_encoded)
        end

        it "uses default document name" do
          expect(applet_cfg[:doc_name]).to eq("document.xml")
        end

        describe "xml_cfg" do
          let(:xml_cfg) { applet_cfg[:xml_cfg] }

          it "includes XML timestamp" do
            expect(xml_cfg[:includeXMLTimestamp]).to eq("true")
          end

          it "does not use canonicalization with comments" do
            expect(xml_cfg[:canonicalizationWithComments]).to eq("false")
          end

          it "does not protect key info" do
            expect(xml_cfg[:protectKeyInfo]).to eq("false")
          end
        end
      end

      context "with custom options" do
        let(:options) do
          {
            redirect_url: "/custom/redirect",
            description: "Custom description",
            doc_name: "custom.xml",
            hash_algorithm: "SHA-512",
            response_b64: false
          }
        end

        it "uses custom redirect URL" do
          expect(payload[:redirectUrl]).to eq("/custom/redirect")
        end

        it "uses custom description" do
          expect(payload[:descripcio]).to eq("Custom description")
        end

        it "uses custom document name" do
          expect(payload[:applet_cfg][:doc_name]).to eq("custom.xml")
        end

        it "uses custom hash algorithm" do
          expect(payload[:applet_cfg][:hash_algorithm]).to eq("SHA-512")
        end

        it "uses custom response_b64 setting" do
          expect(payload[:responseB64]).to eq("false")
        end
      end
    end
  end
end
