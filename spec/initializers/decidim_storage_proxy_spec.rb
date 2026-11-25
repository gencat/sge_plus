# frozen_string_literal: true

require "rails_helper"
# Active Storage only loads a service class when a configured service uses it,
# and the test environment only uses Disk.
require "active_storage/service/s3_service"

describe DecidimStorageProxy do
  subject(:url) { Decidim::AssetRouter::Storage.new(blob).url }

  let(:blob) do
    ActiveStorage::Blob.create!(
      key: SecureRandom.base36(28), filename: "file.pdf", content_type: "application/pdf",
      byte_size: 1, checksum: "x", service_name: "test"
    )
  end
  let(:s3_service) do
    ActiveStorage::Service::S3Service.new(
      bucket: "private-bucket", region: "eu-west-1", stub_responses: true,
      access_key_id: "test", secret_access_key: "test"
    )
  end

  around do |example|
    original_route = ActiveStorage.resolve_model_to_route
    original_url_options = ActiveStorage::Current.url_options
    example.run
  ensure
    ActiveStorage.resolve_model_to_route = original_route
    ActiveStorage::Current.url_options = original_url_options
  end

  before do
    allow(blob).to receive(:service).and_return(s3_service)
    ActiveStorage::Current.url_options = { protocol: "https", host: "org.example.org" }
  end

  context "when Active Storage serves files in proxy mode" do
    before { ActiveStorage.resolve_model_to_route = :rails_storage_proxy }

    it "returns the Rails proxy URL on the current host" do
      expect(url).to start_with("https://org.example.org/rails/active_storage/blobs/proxy/")
    end

    it "returns a relative proxy path when there is no current host" do
      ActiveStorage::Current.url_options = nil

      expect(url).to start_with("/rails/active_storage/blobs/proxy/")
    end
  end

  context "when Active Storage serves files in redirect mode" do
    before { ActiveStorage.resolve_model_to_route = :rails_storage_redirect }

    it "keeps Decidim's direct link to the storage service" do
      expect(url).to start_with("https://private-bucket.s3.eu-west-1.amazonaws.com/")
    end
  end
end
