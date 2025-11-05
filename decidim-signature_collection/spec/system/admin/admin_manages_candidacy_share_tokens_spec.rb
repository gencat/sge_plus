# frozen_string_literal: true

require "spec_helper"

describe "Admin manages candidacy share tokens" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let!(:participatory_space) do
    create(:candidacy, organization:)
  end

  it_behaves_like "manage participatory space share tokens" do
    let(:participatory_space_path) { decidim_admin_candidacies.edit_candidacy_path(participatory_space) }
    let(:participatory_spaces_path) { decidim_admin_candidacies.candidacies_path }
  end
end
