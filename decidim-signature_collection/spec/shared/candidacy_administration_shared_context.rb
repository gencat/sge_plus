# frozen_string_literal: true

shared_context "when admins candidacy" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:author) { create(:user, :confirmed, organization:) }
  let(:other_candidacies_type) { create(:candidacies_type, organization:, signature_type: "any") }
  let!(:other_candidacies_type_scope) { create(:candidacies_type_scope, type: other_candidacies_type) }

  let(:candidacy_type) { create(:candidacies_type, organization:) }
  let(:candidacy_scope) { create(:candidacies_type_scope, type: candidacy_type) }
  let!(:candidacy) { create(:candidacy, organization:, scoped_type: candidacy_scope, author:) }

  let(:image1_filename) { "city.jpeg" }
  let(:image1_path) { Decidim::Dev.asset(image1_filename) }
  let(:image2_filename) { "city2.jpeg" }
  let(:image2_path) { Decidim::Dev.asset(image2_filename) }
  let(:image3_filename) { "city3.jpeg" }
  let(:image3_path) { Decidim::Dev.asset(image3_filename) }
end
