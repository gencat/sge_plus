# frozen_string_literal: true

# Decidim's storage router links straight to the storage service (presigned S3
# URLs) when files live in a remote service, skipping the Rails routes. Our S3
# bucket is private and files must be served by the app, so when Active Storage
# runs in proxy mode we always build the Rails routes, which follow
# `config.active_storage.resolve_model_to_route` (:rails_storage_proxy).
#
# See decidim-core/lib/decidim/asset_router/storage.rb
module DecidimStorageProxy
  private

  # Like the Disk service, Rails routes need the organization host, so this
  # makes Decidim set ActiveStorage::Current.url_options when missing.
  def current_host_required?
    proxy_mode? || super
  end

  def blob_url(**options)
    return super unless proxy_mode?
    return unless blob

    route_options = current_host_options.merge(options)
    route_options = options.merge(only_path: true) if route_options[:host].blank?
    routes.rails_blob_url(blob, **default_options, **route_options)
  end

  def representation_url(**options)
    return super unless proxy_mode?

    route_options = current_host_options.merge(options)
    route_options = options.merge(only_path: true) if route_options[:host].blank?
    rails_representation_url(**route_options)
  end

  # The port is always passed (even nil) so the defaults from other hosts are
  # not mixed in.
  def current_host_options
    url_options = ActiveStorage::Current.url_options.to_h
    return {} if url_options[:host].blank?

    url_options.slice(:protocol, :host).merge(port: url_options[:port])
  end

  def proxy_mode?
    ActiveStorage.resolve_model_to_route == :rails_storage_proxy
  end
end

Decidim::AssetRouter::Storage.prepend(DecidimStorageProxy)
