# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidacySignaturesController do
      routes { Decidim::SignatureCollection::Engine.routes }

      let(:organization) { create(:organization) }
      let(:candidacy) { create(:candidacy, organization:) }
      let(:user) { create(:user, :confirmed, organization:) }
      let(:document_number) { "12345678Z" }
      let(:params) do
        {
          candidacy_slug: candidacy.slug,
          candidacies_vote: {
            document_number:,
            document_type: 1,
            name: "John",
            first_surname: "Doe",
            date_of_birth: "1990-01-01",
            postal_code: "08001"
          }
        }
      end
      let(:signature_process) { instance_double("ValidSignador::StartSignatureProcess", call: signature_result) }
      let(:signature_result) { { success: true, sign_url: "https://signador.example.org/sign" } }

      before do
        request.env["decidim.current_organization"] = organization
        stub_const("ValidSignador::StartSignatureProcess", Class.new)
        allow(ValidSignador::StartSignatureProcess).to receive(:new).and_return(signature_process)
      end

      context "when PUT fill_personal_data" do
        context "with a logged user" do
          before { sign_in user, scope: :user }

          it "creates an unsigned vote and redirects to Signador" do
            expect do
              put :store_personal_data, params:
            end.to change { CandidaciesVote.where(candidacy:).count }.by(1)

            expect(CandidaciesVote.last.encrypted_xml_doc_signed).to be_nil
            expect(response).to redirect_to("https://signador.example.org/sign")
          end

          context "when the signature process cannot be started" do
            let(:signature_result) { { success: false, error: "Signador unavailable" } }

            it "redirects back to the personal data step" do
              put(:store_personal_data, params:)

              expect(flash[:alert]).to be_present
              expect(response).to redirect_to(fill_personal_data_candidacy_signatures_path(candidacy))
            end
          end

          context "when the personal data is not valid" do
            let(:document_number) { "12345678A" }

            it "does not register the vote" do
              expect do
                put :store_personal_data, params:
              end.not_to(change { CandidaciesVote.where(candidacy:).count })

              expect(flash[:alert]).to be_present
              expect(response).to render_template(:fill_personal_data)
            end
          end
        end

        context "with a guest user" do
          # Signer identity is verified by Signador, so no session is required.
          it "creates an unsigned vote and redirects to Signador" do
            expect do
              put :store_personal_data, params:
            end.to change { CandidaciesVote.where(candidacy:).count }.by(1)

            expect(response).to redirect_to("https://signador.example.org/sign")
          end
        end

        context "when signatures are not enabled" do
          let(:candidacy) { create(:candidacy, :created, organization:) }

          it "does not register the vote" do
            expect do
              put :store_personal_data, params:
            end.not_to(change { CandidaciesVote.where(candidacy:).count })
          end
        end
      end

      context "when GET fill_personal_data" do
        let(:candidacy) { create(:candidacy, :with_user_extra_fields_collection, organization:) }

        it "renders the personal data step" do
          sign_in user, scope: :user

          get :fill_personal_data, params: { candidacy_slug: candidacy.slug }

          expect(response).to have_http_status(:ok)
          expect(subject.helpers.current_candidacy).to eq(candidacy)
          expect(subject.helpers.extra_data_legal_information).to eq(candidacy.scoped_type.type.extra_fields_legal_information)
        end
      end
    end
  end
end
