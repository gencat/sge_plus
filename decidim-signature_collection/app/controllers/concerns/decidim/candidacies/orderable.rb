# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Candidacies
    # Common logic to ordering resources
    module Orderable
      extend ActiveSupport::Concern

      included do
        include Decidim::Orderable

        # Available orders based on enabled settings
        def available_orders
          @available_orders ||= begin
            available_orders = %w(random recent most_voted most_commented recently_published)
            available_orders
          end
        end

        def default_order
          "random"
        end

        def reorder(candidacies)
          case order
          when "most_voted"
            candidacies.order_by_supports
          when "most_commented"
            candidacies.order_by_most_commented
          when "recent"
            candidacies.order_by_most_recent
          when "recently_published"
            candidacies.order_by_most_recently_published
          else
            candidacies.order_randomly(random_seed)
          end
        end

        def order
          @order ||= detect_order(params[:order]) || current_candidacies_settings.candidacies_order || default_order
        end

        def current_candidacies_settings
          @current_candidacies_settings ||= Decidim::CandidacysSettings.find_or_create_by!(organization: current_organization)
        end
      end
    end
  end
end
