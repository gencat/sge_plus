# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidSignador::StartSignatureProcess do
  subject(:result) { described_class.new(vote: vote, session: {}, url_helpers: url_helpers).call }

  let(:vote) do
    create(
      :candidacy_user_vote,
      encrypted_xml_doc_to_sign: Decidim::SignatureCollection::DataEncryptor.new(secret: Rails.application.secret_key_base).encrypt("<xml/>")
    )
  end
  let(:url_helpers) { double(valid_signador_callback_url: "http://example.org/valid_signador/callback") }
  let(:client) { instance_double(ValidSignador::Client) }

  before do
    allow(ValidSignador::Client).to receive(:new).and_return(client)
  end

  context "when the process starts correctly" do
    before do
      allow(client).to receive(:init_process).and_return("token" => "abc")
      allow(client).to receive(:start_sign_process)
      allow(client).to receive(:sign_url).with(token: "abc").and_return("http://signador.test/?id=abc")
    end

    it "returns the sign url and keeps the vote with its token" do
      expect(result).to eq(success: true, sign_url: "http://signador.test/?id=abc")
      expect(vote.reload.signador_token).to eq("abc")
    end
  end

  context "when Signador fails" do
    before do
      allow(client).to receive(:init_process).and_raise(ValidSignador::ApiError, "Server error")
    end

    it "returns the error and removes the vote" do
      vote

      expect { result }.to change(Decidim::SignatureCollection::CandidaciesVote, :count).by(-1)
      expect(result).to eq(success: false, error: "Server error")
      expect(Decidim::SignatureCollection::CandidaciesVote.find_by(id: vote.id)).to be_nil
    end
  end
end
