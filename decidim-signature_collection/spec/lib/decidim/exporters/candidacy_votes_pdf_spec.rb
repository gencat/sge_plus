# frozen_string_literal: true

require "spec_helper"
require "hexapdf"

module Decidim
  module Exporters
    describe CandidacyVotesPDF do
      subject { described_class.new(candidacy.votes, candidacy) }

      let(:candidacy) { create(:candidacy) }
      let(:period_start) { Time.zone.local(2025, 3, 10) }
      let(:period_end) { Time.zone.local(2025, 5, 20) }
      let(:pdf_text) { extract_text(subject.export.read) }

      before do
        candidacy.type.update!(signature_period_start: period_start, signature_period_end: period_end)
      end

      it "includes the signature period" do
        expect(pdf_text).to include("March 10, 2025").and include("May 20, 2025")
      end

      context "when the signature period has no start" do
        let(:period_start) { nil }

        it "only includes the end date" do
          expect(pdf_text).to include("May 20, 2025")
          expect(pdf_text).not_to include("March 10, 2025")
        end
      end

      context "when the signature period has no end" do
        let(:period_end) { nil }

        it "only includes the start date" do
          expect(pdf_text).to include("March 10, 2025")
          expect(pdf_text).not_to include("May 20, 2025")
        end
      end

      context "when there is a vote" do
        let(:encrypted_metadata) do
          SignatureCollection::VoteForm.from_params(
            candidacy:,
            name: "Maria",
            first_surname: "Garcia",
            second_surname: "Lopez",
            document_type: SignatureCollection::VoteForm.document_types[:nif],
            document_number: "12345678Z",
            date_of_birth: Date.new(1990, 1, 2),
            postal_code: "08001"
          ).encrypted_metadata
        end

        before { create(:candidacy_user_vote, :signed, candidacy:, encrypted_metadata:) }

        it "includes the data of the signer" do
          expect(pdf_text).to include("Maria Garcia Lopez")
            .and include("12345678Z")
            .and include("January 02, 1990")
            .and include("08001")
        end

        context "and it has no metadata" do
          let(:encrypted_metadata) { nil }

          it "exports the vote without the data of the signer" do
            expect(pdf_text).not_to include("12345678Z")
          end
        end
      end

      # The text wraps inside the cells, so the fragments are joined with single spaces.
      def extract_text(pdf)
        fragments = []
        processor = Class.new(HexaPDF::Content::Processor) do
          define_method(:show_text) { |data| fragments << decode_text(data) }
          alias_method :show_text_with_positioning, :show_text
        end

        HexaPDF::Document.new(io: StringIO.new(pdf)).pages.each { |page| page.process_contents(processor.new) }
        fragments.join(" ").squish
      end
    end
  end
end
