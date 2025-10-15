# frozen_string_literal: true

module Decidim
  module Candidacies
    class DownloadYourDataCandidacySerializer < OpenDataCandidacySerializer
      # Serializes a Debate for download your data feature
      #
      # Remove the author information as it is the same of the user that
      # requested the data
      def serialize
        super.except!(:authors)
      end
    end
  end
end
