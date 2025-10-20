# frozen_string_literal: true

shared_examples "create an candidacy type scope" do
  let(:organization) { create(:organization) }
  let(:scope) { create(:scope, organization:) }
  let(:candidacy_type) { create(:candidacies_type, organization:) }

  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      type_id: candidacy_type.id
    )
  end

  describe "call" do
    let(:form_params) do
      {
        supports_required: 1000,
        decidim_scopes_id: scope.id
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

      it "does not create an candidacy type scope" do
        expect do
          command.call
        end.not_to change(Decidim::SignatureCollection::CandidaciesTypeScope, :count)
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "creates a new candidacy type scope" do
        expect do
          command.call
        end.to change(Decidim::SignatureCollection::CandidaciesTypeScope, :count).by(1)
      end
    end
  end
end
