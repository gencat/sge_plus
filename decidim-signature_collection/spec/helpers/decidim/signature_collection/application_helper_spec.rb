# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    RSpec.describe ApplicationHelper do
      let(:organization) { create(:organization) }

      before do
        org = organization
        helper.singleton_class.send(:define_method, :current_organization) { org }
      end

      it "returns types values only for published candidacy types" do
        published = create(:candidacies_type, organization:, published: true)
        unpublished = create(:candidacies_type, organization:, published: false)

        node = helper.filter_types_values

        child_values = (node.node || []).map { |child| child.leaf.value }

        expect(child_values).to include(published.id.to_s)
        expect(child_values).not_to include(unpublished.id.to_s)
      end
    end
  end
end
