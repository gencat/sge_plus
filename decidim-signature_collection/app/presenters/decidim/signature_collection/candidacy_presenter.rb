# frozen_string_literal: true

module Decidim
  module SignatureCollection
    #
    # Decorator for candidacies
    #
    class CandidacyPresenter < SimpleDelegator
      def author
        @author ||= if user_group
                      Decidim::UserGroupPresenter.new(user_group)
                    else
                      Decidim::UserPresenter.new(super)
                    end
      end
    end
  end
end
