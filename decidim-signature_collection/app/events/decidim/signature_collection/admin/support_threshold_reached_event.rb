# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      class SupportThresholdReachedEvent < Decidim::Events::SimpleEvent
        def participatory_space
          resource
        end
      end
    end
  end
end
