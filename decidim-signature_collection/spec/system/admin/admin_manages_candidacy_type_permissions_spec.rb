# frozen_string_literal: true

require "spec_helper"

# We should ideally be using the shared_context for this, but it assumes the
# resource belongs to a component, which is not the case.
describe "Admin manages candidacy type permissions" do
  let(:organization) do
    create(
      :organization,
      available_authorizations: %w(dummy_authorization_handler another_dummy_authorization_handler)
    )
  end
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:participatory_space_engine) { decidim_admin_candidacies }
  let!(:candidacy_type) { create(:candidacies_type, organization:) }

  let(:action) { "vote" }

  let(:index_path) do
    participatory_space_engine.candidacies_types_path
  end
  let(:edit_resource_permissions_path) do
    participatory_space_engine
      .edit_candidacies_type_permissions_path(
        candidacy_type.id,
        resource_name: candidacy_type.resource_manifest.name
      )
  end
  let(:index_class_selector) { ".candidacy-type-#{candidacy_type.id}" }
  let(:resource) { candidacy_type }

  it_behaves_like "manage resource permissions"
end
