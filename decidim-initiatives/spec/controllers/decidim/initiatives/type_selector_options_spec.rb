# frozen_string_literal: true

require "rails_helper"

module Decidim
  module Initiatives
    RSpec.describe "TypeSelectorOptions concern" do
      controller(ActionController::Base) do
        include Decidim::Initiatives::TypeSelectorOptions

        def index
          render plain: available_initiative_types.map(&:id).join(",")
        end
      end

      let(:organization) { create(:organization) }

      before do
        routes.draw { get "index" => "anonymous#index" }
        org = organization
        controller.singleton_class.send(:define_method, :current_organization) { org }
      end

      it "only returns published initiative types" do
        published = create(:initiatives_type, organization:, published: true)
        unpublished = create(:initiatives_type, organization:, published: false)

        create(:initiatives_type_scope, type: published)
        create(:initiatives_type_scope, type: unpublished)

        get :index

        body_ids = response.body.split(",").map(&:to_i)
        expect(body_ids).to include(published.id)
        expect(body_ids).not_to include(unpublished.id)
      end
    end
  end
end
