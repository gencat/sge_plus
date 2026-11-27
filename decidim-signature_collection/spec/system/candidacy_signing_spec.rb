# frozen_string_literal: true

require "spec_helper"

describe "Candidacy signing" do
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:) }
  let(:confirmed_user) { create(:user, :confirmed, organization:) }
  let(:document_number) { "12345678Z" }
  # Signador is an external service: the signature process is stubbed and redirects back to the candidacy.
  let(:signature_result) { { success: true, sign_url: decidim_candidacies.candidacy_path(candidacy) } }
  let(:signature_process) { double(call: signature_result) }

  before do
    stub_const("ValidSignador::StartSignatureProcess", Class.new)
    allow(ValidSignador::StartSignatureProcess).to receive(:new).and_return(signature_process)
    switch_to_host(organization.host)
    login_as confirmed_user, scope: :user
  end

  context "when candidacy type only allows In-person signatures" do
    let(:candidacy) { create(:candidacy, organization:, signature_type: "offline") }

    it "voting disabled message is shown" do
      visit decidim_candidacies.candidacy_path(candidacy)

      expect(page).to have_content("Signing disabled")
    end

    it "shows the offline supports received" do
      candidacy.update(offline_votes: { candidacy.scoped_type.scope.id.to_s => 1357, "total" => 1357 })

      visit decidim_candidacies.candidacy_path(candidacy)

      expect(page).to have_content("1357 1000\nSignatures")
    end
  end

  context "when the user signs the candidacy" do
    it "creates an unsigned signature and starts the Signador process" do
      fill_personal_data

      expect(page).to have_current_path(decidim_candidacies.candidacy_path(candidacy))
      expect(Decidim::SignatureCollection::CandidaciesVote.where(candidacy:).count).to eq(1)
      expect(Decidim::SignatureCollection::CandidaciesVote.last.encrypted_xml_doc_signed).to be_nil

      within ".candidacy__aside" do
        expect(page).to have_content(signature_text(0))
      end
    end

    context "when the signature process cannot be started" do
      let(:signature_result) { { success: false, error: "Signador unavailable" } }

      it "shows an error" do
        fill_personal_data

        expect(page).to have_content("There was a problem signing the candidacy.")
        expect(page).to have_current_path(decidim_candidacies.fill_personal_data_candidacy_signatures_path(candidacy))
      end
    end

    context "when the personal data is not valid" do
      let(:document_number) { "12345678A" }

      it "does not register the signature" do
        fill_personal_data

        expect(page).to have_content("Personal data is not consistent with data provided for authorization.")
        expect(Decidim::SignatureCollection::CandidaciesVote.where(candidacy:).count).to eq(0)
      end
    end

    context "when the document number has already signed the candidacy" do
      before do
        hash_id = Decidim::SignatureCollection::VoteForm.from_params(candidacy:, document_number:).hash_id
        create(:candidacy_user_vote, candidacy:, hash_id:)
      end

      it "does not register the signature" do
        fill_personal_data

        expect(page).to have_content("Personal data is not consistent with data provided for authorization.")
        expect(Decidim::SignatureCollection::CandidaciesVote.where(candidacy:).count).to eq(1)
      end
    end
  end

  context "when Signador has signed the signature" do
    before do
      create(:candidacy_user_vote, :signed, candidacy:)
    end

    it "counts the signature" do
      visit decidim_candidacies.candidacy_path(candidacy)

      within ".candidacy__aside" do
        expect(page).to have_content(signature_text(1))
      end
    end
  end

  # Votes have no author (removed in 20251222131109), so signatures cannot be removed.
  context "when the user has signed the candidacy" do
    before do
      create(:candidacy_user_vote, :signed, candidacy:)
    end

    it "does not offer to remove the signature" do
      visit decidim_candidacies.candidacy_path(candidacy)

      within ".candidacy__aside" do
        expect(page).to have_link("Sign")
        expect(page).to have_no_content("Already signed")
        expect(page).to have_no_css("form[action*='candidacy_vote']")
      end
    end
  end

  def fill_personal_data
    visit decidim_candidacies.candidacy_path(candidacy)

    within ".candidacy__aside" do
      click_on "Sign"
    end

    fill_in :candidacies_vote_name, with: "John"
    fill_in :candidacies_vote_first_surname, with: "Doe"
    select "NIF", from: :candidacies_vote_document_type
    fill_in :candidacies_vote_document_number, with: document_number
    fill_in_datepicker :candidacies_vote_date_of_birth_date, with: "01/01/1990"
    fill_in :candidacies_vote_postal_code, with: "08001"
    click_on "Continue"
  end

  def signature_text(number)
    return "1 #{candidacy.supports_required}\nSignature" if number == 1

    "#{number} #{candidacy.supports_required}\nSignatures"
  end
end
