# frozen_string_literal: true

shared_examples "update an candidacy" do
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:) }

  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      current_organization: organization,
      current_component: nil,
      current_user:,
      candidacy:
    )
  end

  let(:signature_end_date) { Date.current + 130.days }
  let(:attachment_params) { nil }
  let(:form_params) do
    {
      title: { en: "A reasonable candidacy title" },
      description: { en: "A reasonable candidacy description" },
      signature_start_date: Date.current + 10.days,
      signature_end_date:,
      signature_type: "any",
      type_id: candidacy.type.id,
      decidim_scope_id: candidacy.scope.id,
      hashtag: "update_candidacy_example",
      offline_votes: { candidacy.scope.id.to_s => 1 },
      attachment: attachment_params
    }
  end
  let(:current_user) { candidacy.author }

  let(:command) { described_class.new(form, candidacy) }

  describe "call" do
    describe "when the form is not valid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "does not updates the candidacy" do
        expect do
          command.call
        end.not_to change(candidacy, :title)
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "updates the candidacy" do
        command.call
        candidacy.reload

        expect(candidacy.title["en"]).to eq(form_params[:title][:en])
        expect(candidacy.description["en"]).to eq(form_params[:description][:en])
        expect(candidacy.type.id).to eq(form_params[:type_id])
        expect(candidacy.hashtag).to eq(form_params[:hashtag])
      end

      context "when attachment is present" do
        let(:blob) do
          ActiveStorage::Blob.create_and_upload!(
            io: File.open(Decidim::Dev.test_file("city.jpeg", "image/jpeg"), "rb"),
            filename: "city.jpeg",
            content_type: "image/jpeg" # Or figure it out from `name` if you have non-JPEGs
          )
        end
        let(:attachment_params) do
          {
            title: "My attachment",
            file: blob.signed_id
          }
        end

        it "creates an attachment for the proposal" do
          expect { command.call }.to change(Decidim::Attachment, :count).by(1)
          last_candidacy = Decidim::SignatureCollection::Candidacy.last
          last_attachment = Decidim::Attachment.last
          expect(last_attachment.attached_to).to eq(last_candidacy)
        end

        context "when attachment is left blank" do
          let(:attachment_params) do
            {
              title: ""
            }
          end

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end
        end
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(candidacy, candidacy.author, kind_of(Hash))
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)
        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
      end

      it "voting interval remains unchanged" do
        command.call
        candidacy.reload

        [:signature_start_date, :signature_end_date].each do |key|
          expect(candidacy[key]).not_to eq(form_params[key])
        end
      end

      it "offline votes remain unchanged" do
        command.call
        candidacy.reload
        expect(candidacy.offline_votes[candidacy.scope.id.to_s]).not_to eq(form_params[:offline_votes][candidacy.scope.id.to_s])
      end

      describe "when in created state" do
        let!(:candidacy) { create(:candidacy, :created, signature_type: "online") }

        before { form.signature_type = "offline" }

        it "updates signature type" do
          expect { command.call }.to change(candidacy, :signature_type).from("online").to("offline")
        end
      end

      describe "when not in created state" do
        let!(:candidacy) { create(:candidacy, signature_type: "online") }

        before { form.signature_type = "offline" }

        it "does not update signature type" do
          expect { command.call }.not_to change(candidacy, :signature_type)
        end
      end

      context "when administrator user" do
        let(:current_user) { create(:user, :admin, organization:) }

        let(:command) do
          described_class.new(form, candidacy)
        end

        it "voting interval gets updated" do
          command.call
          candidacy.reload

          [:signature_start_te, :signature_end_date].each do |key|
            expect(candidacy[key]).to eq(form_params[key])
          end
        end

        it "offline votes gets updated" do
          command.call
          candidacy.reload
          expect(candidacy.offline_votes[candidacy.scope.id.to_s]).to eq(form_params[:offline_votes][candidacy.scope.id.to_s])
        end

        it "offline votes maintains a total" do
          command.call
          candidacy.reload
          expect(candidacy.offline_votes["total"]).to eq(form_params[:offline_votes][candidacy.scope.id.to_s])
        end
      end
    end
  end
end
