# frozen_string_literal: true

shared_examples "create an candidacy type" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }

  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      current_organization: organization,
      current_component: nil,
      current_user: user
    )
  end

  describe "call" do
    let(:form_params) do
      {
        title: Decidim::Faker::Localized.sentence(word_count: 5),
        description: Decidim::Faker::Localized.sentence(word_count: 25),
        signature_type: "online",
        attachments_enabled: true,
        undo_online_signatures_enabled: false,
        custom_signature_end_date_enabled: true,
        comments_enabled: true,
        collect_user_extra_fields: false,
        promoting_committee_enabled: true,
        minimum_committee_members: 7,
        banner_image: Decidim::Dev.test_file("city2.jpeg", "image/jpeg"),
        extra_fields_legal_information: Decidim::Faker::Localized.sentence(word_count: 25),
        child_scope_threshold_enabled: false,
        only_global_scope_enabled: false,
        signature_period_start: 1.month.from_now,
        signature_period_end: 2.months.from_now,
        minimum_signing_age: 16,
        elections: "congress"
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

      it "does not create an candidacy type" do
        expect do
          command.call
        end.not_to change(Decidim::SignatureCollection::CandidaciesType, :count)
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "creates a new candidacy type" do
        expect do
          command.call
        end.to change(Decidim::SignatureCollection::CandidaciesType, :count).by(1)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with(:create, Decidim::SignatureCollection::CandidaciesType, user, {})
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)
        action_log = Decidim::ActionLog.last
        expect(action_log.action).to eq("create")
        expect(action_log.version).to be_present
      end
    end
  end
end
