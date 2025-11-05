# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe UpdateCandidaciesSettings do
        subject { described_class.new(form, candidacies_settings) }

        let(:organization) { create(:organization) }
        let(:user) { create(:user, :admin, :confirmed, organization:) }
        let(:candidacies_settings) { create(:candidacies_settings, organization:) }
        let(:candidacies_order) { "date" }
        let(:form) do
          double(
            invalid?: invalid,
            current_user: user,
            candidacies_order:
          )
        end
        let(:invalid) { false }

        context "when the form is not valid" do
          let(:invalid) { true }

          it "is not valid" do
            expect { subject.call }.to broadcast(:invalid)
          end
        end

        context "when the form is valid" do
          it "broadcasts ok" do
            expect { subject.call }.to broadcast(:ok)
          end

          it "updates the candidacies settings" do
            subject.call
            expect(candidacies_settings.candidacies_order).to eq(candidacies_order)
          end
        end
      end
    end
  end
end
