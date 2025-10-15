# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe CandidacysSettings do
    subject(:candidacies_settings) { create(:candidacies_settings) }

    it { is_expected.to be_valid }

    it "overwrites the log presenter" do
      expect(described_class.log_presenter_class_for(:foo))
        .to eq Decidim::Candidacies::AdminLog::CandidacysSettingsPresenter
    end

    context "without organization" do
      before do
        candidacies_settings.organization = nil
      end

      it { is_expected.to be_invalid }
    end
  end
end
