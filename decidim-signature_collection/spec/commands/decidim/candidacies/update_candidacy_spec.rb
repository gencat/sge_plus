# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    describe UpdateCandidacy do
      let(:form_klass) { Decidim::Candidacies::CandidacyForm }
      let(:organization) { create(:organization) }
      let!(:candidacy) { create(:candidacy, organization:) }
      let!(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_organization: organization,
          candidacy:,
          candidacy_type: candidacy.type
        )
      end
      let(:signature_type) { "online" }
      let(:hashtag) { nil }
      let(:attachment) { nil }
      let(:uploaded_files) { [] }
      let(:current_files) { [] }

      describe "call" do
        let(:title) { "Changed Title" }
        let(:description) { "Changed description" }
        let(:type_id) { candidacy.type.id }
        let(:form_params) do
          {
            title:,
            description:,
            signature_type:,
            type_id:,
            attachment:,
            add_documents: uploaded_files,
            documents: current_files
          }
        end
        let(:command) do
          described_class.new(candidacy, form)
        end

        describe "when the form is not valid" do
          before do
            allow(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "does not update the candidacy" do
            expect do
              command.call
            end.not_to change(candidacy, :title)
          end
        end

        describe "when the form is valid" do
          it_behaves_like "fires an ActiveSupport::Notification event", "decidim.candidacies.update_candidacy:before"
          it_behaves_like "fires an ActiveSupport::Notification event", "decidim.candidacies.update_candidacy:after"

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "updates the candidacy" do
            command.call
            candidacy.reload
            expect(candidacy.title).to be_a(Hash)
            expect(candidacy.title["en"]).to eq title
            expect(candidacy.description).to be_a(Hash)
            expect(candidacy.description["en"]).to eq description
          end

          context "when the candidacy type enables custom signature end date" do
            let(:candidacy_type) { create(:candidacies_type, :custom_signature_end_date_enabled, organization:) }
            let(:scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }
            let!(:candidacy) { create(:candidacy, :created, organization:, scoped_type:) }

            let(:form_params) do
              {
                title:,
                description:,
                signature_type:,
                type_id: candidacy_type.id,
                attachment:,
                add_documents: uploaded_files,
                documents: current_files,
                signature_end_date: Date.tomorrow
              }
            end

            it "sets the signature end date" do
              command.call
              candidacy = Decidim::Candidacy.last

              expect(candidacy.signature_end_date).to eq(Date.tomorrow)
            end
          end

          context "when the candidacy type enables area" do
            let(:candidacy_type) { create(:candidacies_type, :area_enabled, organization:) }
            let(:scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }
            let!(:candidacy) { create(:candidacy, :created, organization:, scoped_type:) }
            let(:area) { create(:area, organization: candidacy_type.organization) }

            let(:form_params) do
              {
                title: "A reasonable candidacy title",
                description: "A reasonable candidacy description",
                type_id: candidacy_type.id,
                signature_type: "online",
                decidim_user_group_id: nil,
                area_id: area.id
              }
            end

            it "sets the area" do
              command.call
              candidacy = Decidim::Candidacy.last

              expect(candidacy.decidim_area_id).to eq(area.id)
            end
          end

          context "when attachments are allowed" do
            let(:uploaded_files) do
              [
                upload_test_file(Decidim::Dev.test_file("Exampledocument.pdf", "application/pdf")),
                upload_test_file(Decidim::Dev.test_file("Exampledocument.pdf", "application/pdf"))
              ]
            end

            it "creates multiple attachments for the candidacy" do
              expect { command.call }.to change(Decidim::Attachment, :count).by(2)
              candidacy.reload
              last_attachment = Decidim::Attachment.last
              expect(last_attachment.attached_to).to eq(candidacy)
            end

            context "when the candidacy already had some attachments" do
              let!(:document) { create(:attachment, :with_pdf, attached_to: candidacy) }
              let(:current_files) { [document.id] }

              it "keeps the new and old attachments" do
                command.call
                candidacy.reload
                expect(candidacy.documents.count).to eq(3)
              end

              context "when the old attachments are deleted by the user" do
                let(:current_files) { [] }

                it "deletes the old attachments" do
                  command.call
                  candidacy.reload
                  expect(candidacy.documents.count).to eq(2)
                  expect(candidacy.documents).not_to include(document)
                end
              end
            end
          end

          context "when attachments are allowed and file is invalid" do
            let(:uploaded_files) do
              [
                upload_test_file(Decidim::Dev.test_file("city.jpeg", "image/jpeg")),
                upload_test_file(Decidim::Dev.test_file("invalid_extension.log", "text/plain"))
              ]
            end

            it "does not create attachments for the candidacy" do
              expect { command.call }.not_to change(Decidim::Attachment, :count)
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end
          end
        end
      end
    end
  end
end
