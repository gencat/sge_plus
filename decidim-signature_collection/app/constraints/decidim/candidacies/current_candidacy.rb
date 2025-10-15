# frozen_string_literal: true

module Decidim
  module Candidacies
    # This class infers the current candidacy we are scoped to by
    # looking at the request parameters and the organization in the request
    # environment, and injects it into the environment.
    class CurrentCandidacy
      include CandidacySlug

      # Public: Matches the request against an candidacy and injects it
      #         into the environment.
      #
      # request - The request that holds the candidacy relevant
      #           information.
      #
      # Returns a true if the request matched, false otherwise
      def matches?(request)
        env = request.env

        @organization = env["decidim.current_organization"]
        return false unless @organization

        current_candidacy(env, request.params) ? true : false
      end

      private

      def current_candidacy(env, params)
        env["decidim.current_participatory_space"] ||= Candidacy.find_by(id: id_from_slug(params[:candidacy_slug]))
      end
    end
  end
end
