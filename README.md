# sge_plus

Free Open-Source participatory democracy, citizen participation and open government for cities and organizations

This is the open-source repository for SGE+. SGE+ is based on [Decidim](https://github.com/decidim/decidim).

## Development

```bash
bundle install
nvm use 22.14.0
npm install
bin/rails db:create db:schema:load
bin/rails db:seed
bin/dev
```
## Testing

Run `bin/rake decidim:generate_external_test_app` to generate a dummy application to test both the application and the modules.

Require missing factories in `spec/factories.rb`

Add `require "spec_helper"` to your specs and execute them from the root directory, i.e.:

```bash
bundle exec rspec --backtrace
```

## Metrics (Prometheus)

The app reports Puma stats and a custom Solid Queue collector (see
`config/puma.rb` and `lib/prometheus_exporter/server/solid_queue_collector.rb`)
through the [`prometheus_exporter`](https://github.com/discourse/prometheus_exporter)
gem. To inspect these metrics locally:

### 1. Start the app's exporter process

With the app running (`bin/dev`), start the standalone exporter in a separate
terminal:

```bash
bundle exec prometheus_exporter -a lib/prometheus_exporter/server/solid_queue_collector.rb
```

This exposes the raw metrics at `http://localhost:9394/metrics` (check with
`curl http://localhost:9394/metrics`).

### 2. Start a local Prometheus server to scrape it

Use the sample scrape config at `docker/prometheus/prometheus.yml`:

```bash
docker run --rm --name prometheus_local \
  --network host \
  -v "$(pwd)/docker/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  prom/prometheus:latest
```

Prometheus will be available at `http://localhost:9090`. From the "Graph" tab
you can query metrics such as `solid_queue_ready_jobs`, `solid_queue_failed_jobs`
or the Puma pool stats.

> `--network host` only works on Linux. On Docker Desktop (Mac/Windows), drop
> that flag, add `-p 9090:9090`, and change the target in
> `docker/prometheus/prometheus.yml` to `host.docker.internal:9394`.
