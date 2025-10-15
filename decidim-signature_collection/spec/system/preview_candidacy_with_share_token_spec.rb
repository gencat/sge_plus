# frozen_string_literal: true

require "spec_helper"

describe "Preview candidacy with share token" do
  let(:organization) { create(:organization) }
  let!(:participatory_space) { create(:candidacy, :created, organization:) }
  let(:resource_path) { decidim_candidacies.candidacy_path(participatory_space) }

  it_behaves_like "preview participatory space with a share_token"
end
