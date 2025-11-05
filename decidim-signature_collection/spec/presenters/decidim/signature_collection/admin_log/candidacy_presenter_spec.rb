# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::AdminLog::CandidacyPresenter, type: :helper do
  include_examples "present admin log entry" do
    let(:admin_log_resource) { create(:candidacy, organization:) }
    let(:action) { "publish" }
  end
end
