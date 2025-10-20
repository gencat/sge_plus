# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # This controller allows exporting things.
      # It is targeted for customizations for exporting things that lives under
      # a participatory process.
      class ExportsController < Decidim::Admin::ExportsController
        include CandidacyAdmin
      end
    end
  end
end
