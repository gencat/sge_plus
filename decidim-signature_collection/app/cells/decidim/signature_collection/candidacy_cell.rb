# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This cell renders the process card for an instance of an Candidacy
    # the default size is the Medium Card (:m)
    class CandidacyCell < Decidim::ViewModel
      def show
        cell card_size, model, options
      end

      private

      def card_size
        case @options[:size]
        when :s
          "decidim/signature_collection/candidacy_s"
        else
          "decidim/signature_collection/candidacy_g"
        end
      end
    end
  end
end
