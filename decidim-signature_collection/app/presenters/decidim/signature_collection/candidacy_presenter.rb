# frozen_string_literal: true

module Decidim
  module SignatureCollection
    #
    # Decorator for candidacies
    #
    class CandidacyPresenter < Decidim::ResourcePresenter
      def author
        @author ||= if user_group
                      Decidim::UserGroupPresenter.new(user_group)
                    else
                      Decidim::UserPresenter.new(super)
                    end
      end

      def title(html_escape: false, all_locales: false)
        return unless __getobj__

        super(__getobj__.title, html_escape, all_locales)
      end
    end
  end
end
