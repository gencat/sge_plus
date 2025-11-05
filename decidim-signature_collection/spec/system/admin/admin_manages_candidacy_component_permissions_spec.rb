# frozen_string_literal: true

require "spec_helper"
require "decidim/admin/test/manage_component_permissions_examples"

describe "Admin manages candidacy component permissions" do
  include_examples "Managing component permissions" do
    let(:user) { create(:user, :admin, :confirmed, organization:) }
    let(:participatory_space_engine) { decidim_admin_candidacies }

    let!(:participatory_space) do
      create(:candidacy, organization:)
    end
  end
end
