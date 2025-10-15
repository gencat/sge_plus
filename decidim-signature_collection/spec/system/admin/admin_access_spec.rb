# frozen_string_literal: true

require "spec_helper"

describe "AdminAccess" do
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when the user is a normal user" do
    let(:user) { create(:user, :confirmed, organization:) }
    let(:unauthorized_path) { "/" }

    it_behaves_like "a 404 page" do
      let(:target_path) { decidim_admin_candidacies.edit_candidacy_path(candidacy) }
    end
  end

  context "when the user is the author of the candidacy" do
    let(:user) { create(:user, :confirmed, organization:) }
    let(:candidacy) { create(:candidacy, author: user, organization:) }
    let(:unauthorized_path) { "/" }

    it_behaves_like "a 404 page" do
      let(:target_path) { decidim_admin_candidacies.edit_candidacy_path(candidacy) }
    end
  end
end
