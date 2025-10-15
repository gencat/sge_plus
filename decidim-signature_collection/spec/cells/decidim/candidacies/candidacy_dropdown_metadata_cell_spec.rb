# frozen_string_literal: true

require "spec_helper"

require "decidim/core/test/shared_examples/participatory_space_dropdown_metadata_cell_examples"

module Decidim::Candidacies
  describe CandidacyDropdownMetadataCell, type: :cell do
    controller Decidim::ApplicationController

    subject { cell("decidim/candidacies/candidacy_dropdown_metadata", model).call }

    let(:model) { create(:candidacy, hashtag:) }
    let(:hashtag) { nil }

    include_examples "participatory space dropdown metadata cell"
    include_examples "participatory space dropdown metadata cell hashtag"
  end
end
