# frozen_string_literal: true

require "rails_helper"

module ValidSignador
  RSpec.describe Configuration do
    describe "#initialize" do
      context "with all required environment variables" do
        before do
          ENV["SIGNADOR_DOMAIN"] = "https://example.cat"
          ENV["SIGNADOR_API_KEY"] = "test_api_key"
          ENV["SIGNADOR_BASE_URL"] = "https://signador-pre.aoc.cat/signador"
        end

        after do
          ENV.delete("SIGNADOR_DOMAIN")
          ENV.delete("SIGNADOR_API_KEY")
          ENV.delete("SIGNADOR_BASE_URL")
        end

        it "initializes with correct values" do
          config = described_class.new

          expect(config.domain).to eq("https://example.cat")
          expect(config.api_key).to eq("test_api_key")
          expect(config.base_url).to eq("https://signador-pre.aoc.cat/signador")
        end

        it "builds callback_url correctly" do
          config = described_class.new

          expect(config.callback_url).to eq("https://example.cat/valid_signador/callback")
        end
      end

      context "without required environment variables" do
        before do
          ENV.delete("SIGNADOR_DOMAIN")
          ENV.delete("SIGNADOR_API_KEY")
        end

        it "raises ConfigurationError when domain is missing" do
          expect { described_class.new }.to raise_error(ConfigurationError, /SIGNADOR_DOMAIN is required/)
        end
      end

      context "with custom callback path" do
        before do
          ENV["SIGNADOR_DOMAIN"] = "https://example.cat"
          ENV["SIGNADOR_API_KEY"] = "test_api_key"
          ENV["SIGNADOR_BASE_URL"] = "https://signador-pre.aoc.cat/signador"
          ENV["SIGNADOR_CALLBACK_PATH"] = "/custom/callback"
        end

        after do
          ENV.delete("SIGNADOR_DOMAIN")
          ENV.delete("SIGNADOR_API_KEY")
          ENV.delete("SIGNADOR_CALLBACK_PATH")
        end

        it "uses custom callback path" do
          config = described_class.new

          expect(config.callback_url).to eq("https://example.cat/custom/callback")
        end
      end
    end
  end
end
