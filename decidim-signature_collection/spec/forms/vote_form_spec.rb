# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe VoteForm do
      subject { form }

      let(:form) { described_class.from_params(attributes).with_context(context) }

      let(:organization) { create(:organization) }
      let(:candidacy) { create(:candidacy, organization:) }

      let(:document_type) { described_class.document_types[:nif] }
      let(:document_number) { "12345678Z" }
      let(:personal_data) do
        {
          name: "James",
          first_surname: "Morgan",
          second_surname: "McGill",
          document_type:,
          document_number:,
          date_of_birth: 40.years.ago.to_date,
          postal_code: "08001"
        }
      end

      let(:attributes) { personal_data.merge(candidacy:) }
      let(:context) { { current_organization: organization } }

      context "when everything is OK" do
        it { is_expected.to be_valid }
      end

      context "when personal data is blank" do
        let(:personal_data) { {} }

        it { is_expected.not_to be_valid }
      end

      %w(name first_surname document_type document_number date_of_birth postal_code).each do |field|
        context "when #{field} is missing" do
          let(:attributes) { personal_data.except(field.to_sym).merge(candidacy:) }

          it { is_expected.not_to be_valid }
        end
      end

      context "when second surname is missing" do
        let(:attributes) { personal_data.except(:second_surname).merge(candidacy:) }

        it { is_expected.to be_valid }
      end

      context "when there is no candidacy" do
        let(:attributes) { personal_data }

        it { is_expected.not_to be_valid }
      end

      describe "document number" do
        context "with a NIF with a wrong letter" do
          let(:document_number) { "12345678A" }

          it "is not valid" do
            expect(form).not_to be_valid
            expect(form.errors.details[:document_number]).to include(error: :invalid_nif_letter)
          end
        end

        context "with a NIF with a wrong format" do
          let(:document_number) { "1234567Z" }

          it "is not valid" do
            expect(form).not_to be_valid
            expect(form.errors.details[:document_number]).to include(error: :invalid_nif_format)
          end
        end

        context "with a lowercase NIF" do
          let(:document_number) { "12345678z" }

          it { is_expected.to be_valid }
        end

        context "with a NIE" do
          let(:document_type) { described_class.document_types[:nie] }
          let(:document_number) { "X1234567L" }

          it { is_expected.to be_valid }

          context "with a wrong letter" do
            let(:document_number) { "X1234567A" }

            it "is not valid" do
              expect(form).not_to be_valid
              expect(form.errors.details[:document_number]).to include(error: :invalid_nie_letter)
            end
          end

          context "with a wrong format" do
            let(:document_number) { "12345678Z" }

            it "is not valid" do
              expect(form).not_to be_valid
              expect(form.errors.details[:document_number]).to include(error: :invalid_nie_format)
            end
          end
        end
      end

      describe "#hash_id" do
        it "is the same for the same candidacy and document number" do
          other_form = described_class.from_params(attributes.merge(name: "Other")).with_context(context)

          expect(form.hash_id).to eq(other_form.hash_id)
        end

        it "changes with the document number" do
          other_form = described_class.from_params(attributes.merge(document_number: "87654321X")).with_context(context)

          expect(form.hash_id).not_to eq(other_form.hash_id)
        end

        it "changes with the candidacy" do
          other_form = described_class.from_params(attributes.merge(candidacy: create(:candidacy, organization:))).with_context(context)

          expect(form.hash_id).not_to eq(other_form.hash_id)
        end
      end

      context "when the document number has already signed the candidacy" do
        before do
          create(:candidacy_user_vote, candidacy:, hash_id: form.hash_id)
        end

        it "is not valid" do
          expect(form).not_to be_valid
          expect(form.errors.details[:document_number]).to include(error: :taken)
        end
      end

      describe "#encrypted_metadata" do
        it "can be decrypted with the personal data" do
          decrypted = DataEncryptor.new(secret: Rails.application.secret_key_base).decrypt(form.encrypted_metadata)

          expect(decrypted).to eq(personal_data.as_json)
        end
      end

      describe "#filename" do
        it "is named after the document number" do
          expect(form.filename).to eq("12345678Z.xml")
        end
      end
    end
  end
end
