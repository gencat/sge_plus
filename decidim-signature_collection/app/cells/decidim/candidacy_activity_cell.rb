# frozen_string_literal: true

module Decidim
  # A cell to display when an candidacy has been published.
  class CandidacyActivityCell < ActivityCell
    def title
      I18n.t "decidim.candidacies.last_activity.new_candidacy"
    end
  end
end
