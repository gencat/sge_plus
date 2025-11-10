# frozen_string_literal: true

shared_examples "create an candidacy" do
  let(:candidacy_type) { create(:candidacies_type) }
  let(:scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }
  let(:current_user) { create(:user, organization: candidacy_type.organization) }
  let(:form) do
    form_klass
      .from_params(form_params)
      .with_context(
        current_organization: candidacy_type.organization,
        candidacy_type:,
        current_user:
      )
  end
  let(:uploaded_files) { [] }
  let(:current_files) { [] }

  describe "call" do
    let(:form_params) do
      {
        title: "A reasonable candidacy title",
        description: "A reasonable candidacy description",
        type_id: scoped_type.type.id,
        signature_type: "online",
        scope_id: scoped_type.scope.id,
        decidim_user_group_id: nil,
        add_documents: uploaded_files,
        documents: current_files
      }
    end

    let(:command) { described_class.new(form) }

    describe "when the form is not valid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "does not create an candidacy" do
        expect do
          command.call
        end.not_to change(Decidim::SignatureCollection::Candidacy, :count)
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "creates a new candidacy" do
        expect do
          command.call
        end.to change(Decidim::SignatureCollection::Candidacy, :count).by(1)
      end

      it "sets the author" do
        command.call
        candidacy = Decidim::SignatureCollection::Candidacy.last

        expect(candidacy.author).to eq(current_user)
      end

      it "Default state is created" do
        command.call
        candidacy = Decidim::SignatureCollection::Candidacy.last

        expect(candidacy).to be_created
      end

      it "Title and description are stored with its locale" do
        command.call
        candidacy = Decidim::SignatureCollection::Candidacy.last

        expect(candidacy.title.keys).not_to be_empty
        expect(candidacy.description.keys).not_to be_empty
      end

      it "Voting interval is not set yet" do
        command.call
        candidacy = Decidim::SignatureCollection::Candidacy.last

        expect(candidacy).not_to have_signature_interval_defined
      end

      it "adds the author as follower" do
        command.call do
          on(:ok) do |assembly|
            expect(author.follows?(assembly)).to be_true
          end
        end
      end

      it "adds the author as committee member in accepted state" do
        command.call
        candidacy = Decidim::SignatureCollection::Candidacy.last

        expect(candidacy.committee_members.accepted.where(user: current_user)).to exist
      end

      context "when the candidacy type does not enable custom signature end date" do
        it "does not set the signature end date" do
          command.call
          candidacy = Decidim::SignatureCollection::Candidacy.last

          expect(candidacy.signature_end_date).to be_nil
        end
      end
    end
  end
end
