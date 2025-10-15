# frozen_string_literal: true

require "spec_helper"

describe "Candidacy signing" do
  let(:organization) { create(:organization, available_authorizations: authorizations) }
  let(:candidacy) { create(:candidacy, organization:, scoped_type: create(:candidacies_type_scope, type: candidacies_type)) }
  let(:candidacies_type) { create(:candidacies_type, :with_user_extra_fields_collection, :with_sms_code_validation, organization:) }
  let(:confirmed_user) { create(:user, :confirmed, organization:) }
  let(:authorizations) { ["sms"] }
  let(:document_number) { "0123345678A" }
  let(:phone_number) { "666666666" }
  let!(:verification_form) { Decidim::Verifications::Sms::MobilePhoneForm.new(mobile_phone_number: phone_number) }
  let(:unique_id) { verification_form.unique_id }
  let(:sms_code) { "12345" }
  let!(:authorization) do
    create(
      :authorization,
      :granted,
      name: "dummy_authorization_handler",
      user: confirmed_user,
      unique_id: document_number,
      metadata: { document_number:, postal_code: "01234", scope_id: candidacy.scope.id }
    )
  end

  before do
    allow(Decidim::Candidacies)
      .to receive(:do_not_require_authorization)
      .and_return(true)
    switch_to_host(organization.host)
    login_as confirmed_user, scope: :user
    visit decidim_candidacies.candidacy_path(candidacy)

    allow(Decidim::Verifications::Sms::MobilePhoneForm).to receive(:new).and_return(verification_form)
    allow(verification_form).to receive(:verification_metadata).and_return(verification_code: sms_code)

    expect(page).to have_css(".candidacy__aside", text: signature_text(0))

    within ".candidacy__aside" do
      expect(page).to have_content(signature_text(0))
      click_on "Sign"
    end

    if has_content?("Complete your data")
      fill_in :candidacies_vote_name_and_surname, with: confirmed_user.name
      fill_in :candidacies_vote_document_number, with: document_number
      fill_in_datepicker :candidacies_vote_date_of_birth_date, with: 30.years.ago.strftime("01/01/%Y")

      fill_in :candidacies_vote_postal_code, with: "01234"

      click_on "Continue"

      expect(page).to have_no_css("div.alert")
    end
  end

  context "when candidacy type personal data collection is disabled" do
    let(:candidacies_type) { create(:candidacies_type, :with_sms_code_validation, organization:) }

    it "The sms step appears" do
      expect(page).to have_content("Mobile phone number")
    end
  end

  context "when personal data collection is enabled" do
    context "when the user has not signed the candidacy yet an signs it" do
      context "when sms authorization is not available for the site" do
        let(:authorizations) { [] }

        it "The vote is created" do
          expect(page).to have_content("candidacy has been successfully signed")
          click_on "Back to candidacy"

          within ".candidacy__aside" do
            expect(page).to have_content(signature_text(1))
            expect(candidacy.reload.supports_count).to eq(1)
          end
        end
      end

      it "mobile phone is required" do
        expect(page).to have_content("Fill the form with your verified phone number")
        expect(page).to have_content("Send me an SMS")
        expect(candidacy.reload.supports_count).to be_zero
      end

      context "when the user fills phone number" do
        context "without authorization" do
          it "phone number is invalid" do
            fill_phone_number

            expect(page).to have_content("The phone number is invalid or pending of authorization")
            expect(candidacy.reload.supports_count).to be_zero
          end
        end

        context "with valid authorization" do
          before do
            create(:authorization, name: "sms", user: confirmed_user, granted_at: 2.seconds.ago, unique_id:)
          end

          context "and inserts wrong phone number" do
            let(:unique_id) { "wadus" }

            it "appears an invalid message" do
              fill_phone_number

              expect(page).to have_content("The phone number is invalid or pending of authorization")
              expect(candidacy.reload.supports_count).to be_zero
            end
          end

          context "and inserts correct phone number" do
            let(:form_sms_code) { sms_code }

            before do
              fill_phone_number
            end

            it "sms code is required" do
              expect(page).to have_content("Check the SMS received at your phone")
              expect(candidacy.reload.supports_count).to be_zero
            end

            context "and inserts the wrong code number" do
              let(:form_sms_code) { "wadus" }

              it "appears an invalid message" do
                fill_sms_code

                expect(page).to have_content("Your verification code does not match ours")
                expect(candidacy.reload.supports_count).to be_zero
              end
            end

            context "and inserts the correct code number" do
              it "the vote is created" do
                fill_sms_code

                expect(page).to have_content("candidacy has been successfully signed")
                click_on "Back to candidacy"

                expect(page).to have_content(signature_text(1))
                expect(candidacy.reload.supports_count).to eq(1)
              end
            end
          end
        end
      end
    end
  end
end

def fill_phone_number
  fill_in :mobile_phone_mobile_phone_number, with: phone_number
  click_on "Send me an SMS"
end

def fill_sms_code
  fill_in :confirmation_verification_code, with: form_sms_code
  click_on "Check code and continue"
end

def signature_text(number)
  return "1 #{candidacy.supports_required}\nSignature" if number == 1

  "#{number} #{candidacy.supports_required}\nSignatures"
end
