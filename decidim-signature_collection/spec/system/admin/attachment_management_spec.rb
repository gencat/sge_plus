# frozen_string_literal: true

require "spec_helper"
require "decidim/admin/test/manage_attachments_examples"

describe "candidacy attachments" do
  describe "when managed by admin" do
    include_context "when admins candidacy"

    let(:attached_to) { candidacy }
    let(:attachment_collection) { create(:attachment_collection, collection_for: candidacy) }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_candidacies.edit_candidacy_path(candidacy)
      within_admin_sidebar_menu do
        click_on "Attachments"
      end
    end

    it_behaves_like "manage attachments examples"
  end
end
