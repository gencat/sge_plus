# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/download_your_data_shared_examples"

module Decidim
  describe DownloadYourDataExporter do
    subject { DownloadYourDataExporter.new(user, "download-your-data", "CSV") }

    let(:user) { create(:user, :confirmed, organization:) }
    let(:organization) { create(:organization) }

    describe "#readme" do
      context "when the user has an candidacy" do
        let(:candidacies_type) { create(:candidacies_type, organization:) }
        let(:scope) { create(:candidacies_type_scope, type: candidacies_type) }
        let!(:candidacy) { create(:candidacy, author: user, organization:, scoped_type: scope) }

        let(:help_definition_string) { "The title of the candidacy" }

        it_behaves_like "a download your data entity"
      end
    end
  end
end
