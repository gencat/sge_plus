# frozen_string_literal: true

require "spec_helper"
# require "decidim/admin/test/manage_component_permissions_examples"

# We should ideally be using the shared_context for this, but it assumes the
# resource belongs to a component, which is not the case.
describe "Admin manages candidacy permissions" do
  let(:organization) do
    create(
      :organization,
      available_authorizations: %w(dummy_authorization_handler another_dummy_authorization_handler)
    )
  end
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:participatory_space_engine) { decidim_admin_candidacies }
  let!(:candidacy_type) { create(:candidacies_type, :online_signature_enabled, organization:) }
  let!(:scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }
  let(:candidacy) { create(:candidacy, author:, scoped_type:, organization:) }
  let!(:author) { create(:user, :confirmed, organization:) }

  let(:action) { "comment" }

  let(:index_path) do
    participatory_space_engine.candidacies_path
  end
  let(:edit_resource_permissions_path) do
    participatory_space_engine
      .edit_candidacy_permissions_path(
        candidacy,
        resource_name: candidacy.resource_manifest.name
      )
  end
  let(:index_class_selector) { ".candidacy-#{candidacy.id}" }
  let(:resource) { candidacy }

  it_behaves_like "manage resource permissions"
end
