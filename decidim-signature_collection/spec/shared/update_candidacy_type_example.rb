# frozen_string_literal: true

shared_examples "update an candidacy type" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:candidacy_type) do
    create(:candidacies_type,
           :online_signature_enabled,
           :attachments_disabled,
           :undo_online_signatures_enabled,
           organization:)
  end
  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      current_organization: candidacy_type.organization,
      current_component: nil,
      current_user: user
    )
  end

  describe "call" do
    let(:form_params) do
      {
        title: Decidim::Faker::Localized.sentence(word_count: 5).except("machine_translations"),
        description: Decidim::Faker::Localized.sentence(word_count: 25).except("machine_translations"),
        signature_type: "offline",
        attachments_enabled: true,
        undo_online_signatures_enabled: false,
        custom_signature_end_date_enabled: true,
        area_enabled: true,
        comments_enabled: true,
        extra_fields_legal_information: Decidim::Faker::Localized.sentence(word_count: 25).except("machine_translations"),
        document_number_authorization_handler: "",
        child_scope_threshold_enabled: false,
        only_global_scope_enabled: false,
        signature_period_start: 1.month.from_now,
        signature_period_end: 2.months.from_now,
        minimum_signing_age: 16,
        elections: "congress"
      }
    end

    let(:command) { described_class.new(form, candidacy_type) }

    describe "when the form is not valid" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "does not update an candidacy type" do
        command.call
        expect(candidacy_type.title).not_to eq(form_params[:title])
        expect(candidacy_type.description).not_to eq(form_params[:description])
        expect(candidacy_type.signature_type).not_to eq(form_params[:signature_type])
        expect(candidacy_type.attachments_enabled).not_to eq(form_params[:attachments_enabled])
        expect(candidacy_type.undo_online_signatures_enabled).not_to eq(form_params[:undo_online_signatures_enabled])
        expect(candidacy_type.custom_signature_end_date_enabled).not_to eq(form_params[:custom_signature_end_date_enabled])
        expect(candidacy_type.area_enabled).not_to eq(form_params[:area_enabled])
        expect(candidacy_type.minimum_committee_members).not_to eq(form_params[:minimum_committee_members])
      end
    end

    describe "when the form is valid" do
      let(:scope) { create(:candidacies_type_scope, type: candidacy_type) }

      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "updates the candidacy type" do
        command.call

        expect(candidacy_type.title.except("machine_translations")).to eq(form_params[:title])
        expect(candidacy_type.description.except("machine_translations")).to eq(form_params[:description])
        expect(candidacy_type.signature_type).to eq(form_params[:signature_type])
        expect(candidacy_type.attachments_enabled).to eq(form_params[:attachments_enabled])
        expect(candidacy_type.undo_online_signatures_enabled).to eq(form_params[:undo_online_signatures_enabled])
      end

      it "propagates signature type to created candidacies" do
        candidacy = create(:candidacy, :created, organization:, scoped_type: scope, signature_type: "online")

        command.call
        candidacy.reload

        expect(candidacy.signature_type).to eq("offline")
      end

      it "does not propagate signature type to non-created candidacies" do
        candidacy = create(:candidacy, organization:, scoped_type: scope, signature_type: "online")

        command.call
        candidacy.reload

        expect(candidacy.signature_type).to eq("online")
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with(:update, candidacy_type, user, {})
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)
        action_log = Decidim::ActionLog.last
        expect(action_log.action).to eq("update")
        expect(action_log.version).to be_present
      end
    end
  end
end
