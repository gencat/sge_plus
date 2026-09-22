# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Exposes the candidacy vote resource so users can vote candidacies.
    class CandidacyVotesController < Decidim::SignatureCollection::ApplicationController
      include Decidim::SignatureCollection::NeedsCandidacy
      include Decidim::FormFactory

      before_action :authenticate_user!

      helper CandidacyHelper

      # POST /candidacies/:candidacy_id/candidacy_vote
      def create
        enforce_permission_to :vote, :candidacy, candidacy: current_candidacy

        @form = form(Decidim::SignatureCollection::VoteForm).from_params(
          candidacy: current_candidacy
        )

        VoteCandidacy.call(@form) do
          on(:ok) do
            current_candidacy.reload
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: {
              error: I18n.t("candidacy_votes.create.error", scope: "decidim.candidacies")
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
