# frozen_string_literal: true

require "spec_helper"

describe "Comments", skip: "Awaiting review" do

  let(:organization) { create(:organization) }
  let!(:candidacy_type) { create(:candidacies_type, :online_signature_enabled, organization:) }
  let!(:scoped_type) { create(:candidacies_type_scope, type: candidacy_type) }
  let(:commentable) { create(:candidacy, author: user, scoped_type:, organization:) }
  let!(:participatory_space) { commentable }
  let(:component) { nil }
  let(:resource_path) { resource_locator(commentable).path }

  include_examples "comments"
end
