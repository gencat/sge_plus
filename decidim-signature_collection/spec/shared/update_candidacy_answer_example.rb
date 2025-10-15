# frozen_string_literal: true

shared_examples "update an candidacy answer" do
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:, state:) }
  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      current_organization: organization,
      candidacy:
    )
  end
  let(:signature_end_date) { Date.current + 500.days }
  let(:state) { "open" }
  let(:form_params) do
    {
      signature_start_date: Date.current + 10.days,
      signature_end_date:,
      answer: { en: "Measured answer" },
      answer_url: "http://decidim.org"
    }
  end
  let(:administrator) { create(:user, :admin, organization:) }
  let(:command) { described_class.new(candidacy, form) }

  describe "call" do
    describe "when the form is not valid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "does not updates the candidacy" do
        command.call

        form_params.each do |key, value|
          expect(candidacy[key]).not_to eq(value)
        end
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "updates the candidacy" do
        command.call
        candidacy.reload

        expect(candidacy.answer["en"]).to eq(form_params[:answer][:en])
        expect(candidacy.answer_url).to eq(form_params[:answer_url])
      end

      context "when candidacy is not open" do
        let(:state) { "validating" }

        it "voting interval remains unchanged" do
          command.call
          candidacy.reload

          [:signature_start_date, :signature_end_date].each do |key|
            expect(candidacy[key]).not_to eq(form_params[key])
          end
        end
      end

      context "when candidacy is open" do
        it "voting interval is updated" do
          command.call
          candidacy.reload

          [:signature_start_date, :signature_end_date].each do |key|
            expect(candidacy[key]).to eq(form_params[key])
          end
        end
      end
    end
  end
end
