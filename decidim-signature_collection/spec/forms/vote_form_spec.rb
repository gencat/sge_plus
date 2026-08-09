# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe VoteForm do
      subject { form }

      let(:form) { described_class.from_params(attributes).with_context(context) }

      let(:organization) { create(:organization) }
      let!(:city) { create(:scope, organization:) }
      let!(:district1) { create(:subscope, parent: city) }
      let!(:district2) { create(:subscope, parent: city) }
      let!(:neighbourhood1) { create(:subscope, parent: district1) }
      let!(:neighbourhood2) { create(:subscope, parent: district2) }
      let!(:neighbourhood3) { create(:subscope, parent: district1) }
      let!(:neighbourhood4) { create(:subscope, parent: district2) }
      let!(:candidacy_type) do
        create(
          :candidacies_type,
          organization:,
          document_number_authorization_handler:,
          child_scope_threshold_enabled:
        )
      end
      let!(:global_candidacy_type_scope) { create(:candidacies_type_scope, scope: nil, type: candidacy_type) }
      let!(:city_candidacy_type_scope) { create(:candidacies_type_scope, scope: city, type: candidacy_type) }
      let!(:district_1_candidacy_type_scope) { create(:candidacies_type_scope, scope: district1, type: candidacy_type) }
      let!(:district_2_candidacy_type_scope) { create(:candidacies_type_scope, scope: district2, type: candidacy_type) }
      let!(:neighbourhood_1_candidacy_type_scope) { create(:candidacies_type_scope, scope: neighbourhood1, type: candidacy_type) }
      let!(:neighbourhood_2_candidacy_type_scope) { create(:candidacies_type_scope, scope: neighbourhood2, type: candidacy_type) }
      let!(:neighbourhood_3_candidacy_type_scope) { create(:candidacies_type_scope, scope: neighbourhood3, type: candidacy_type) }
      let!(:authorization) do
        create(
          :authorization,
          :granted,
          name: "dummy_authorization_handler",
          user: current_user,
          unique_id: document_number,
          metadata: { document_number:, postal_code:, scope_id: user_scope.id }
        )
      end
      let(:user_scope) { district1 }
      let(:scoped_type) { district_1_candidacy_type_scope }

      let(:candidacy) do
        create(
          :candidacy,
          organization:,
          scoped_type:
        )
      end
      let(:document_number_authorization_handler) { "dummy_authorization_handler" }
      let(:child_scope_threshold_enabled) { false }

      let(:current_user) { create(:user, organization: candidacy.organization) }

      let(:document_number) { "12345678Z" }
      let(:postal_code) { "87111" }
      let(:personal_data) do
        {
          name: "James",
          first_surname: "Morgan",
          second_surname: "McGill",
          document_type: 1,
          document_number: document_number,
          date_of_birth: 40.years.ago.to_date,
          postal_code: postal_code
        }
      end

      let(:vote_attributes) do
        {
          candidacy:
        }
      end
      let(:attributes) { personal_data.merge(vote_attributes) }
      let(:context) { { current_organization: organization } }

      context "when everything is OK" do
        it { is_expected.to be_valid }
      end

      describe "personal data" do
        context "when personal data is blank" do
          let(:personal_data) { {} }

          it { is_expected.not_to be_valid }
        end

        context "when personal data is present" do
          it { is_expected.to be_valid }
        end

        describe "#encrypted_metadata" do
          subject { described_class.from_params(attributes).with_context(context).encrypted_metadata }

          it { is_expected.not_to eq(personal_data) }

          [:name, :first_surname, :second_surname, :document_number, :date_of_birth, :postal_code].each do |personal_attribute|
            it { is_expected.not_to include(personal_data[personal_attribute].to_s) }
          end
        end
      end
    end
  end
end
