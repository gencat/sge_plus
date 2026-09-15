# frozen_string_literal: true

# Custom TypeCollector for Solid Queue: prometheus_exporter has no built-in
# support for it (unlike Sidekiq, Resque, GoodJob or DelayedJob), so this
# reads the queue tables directly on every /metrics scrape, following the
# "Global metrics in a custom type collector" pattern documented in
# https://github.com/discourse/prometheus_exporter#global-metrics-in-a-custom-type-collector
#
# Loaded by the standalone exporter process via:
#   bundle exec prometheus_exporter -a lib/prometheus_exporter/server/solid_queue_collector.rb
require_relative "../../../config/environment" unless defined?(Rails)

module PrometheusExporter::Server
  class SolidQueueCollector < TypeCollector
    def type
      "solid_queue"
    end

    # No client ever pushes this type; metrics are read straight from the
    # database in #metrics instead.
    def collect(_obj); end

    def metrics
      [
        gauge("solid_queue_ready_jobs", "Number of jobs ready to run.", SolidQueue::ReadyExecution.count),
        gauge("solid_queue_scheduled_jobs", "Number of jobs scheduled for future execution.", SolidQueue::ScheduledExecution.count),
        gauge("solid_queue_claimed_jobs", "Number of jobs currently claimed by a worker.", SolidQueue::ClaimedExecution.count),
        gauge("solid_queue_blocked_jobs", "Number of jobs blocked by a concurrency limit.", SolidQueue::BlockedExecution.count),
        gauge("solid_queue_failed_jobs", "Number of jobs that failed and are pending retry or discard.", SolidQueue::FailedExecution.count),
        processes_gauge
      ]
    end

    private

    def gauge(name, help, value)
      PrometheusExporter::Metric::Gauge.new(name, help).tap { |g| g.observe(value) }
    end

    def processes_gauge
      metric = PrometheusExporter::Metric::Gauge.new("solid_queue_processes", "Number of registered Solid Queue processes, by kind.")
      SolidQueue::Process.group(:kind).count.each do |kind, count|
        metric.observe(count, kind: kind)
      end
      metric
    end
  end
end
