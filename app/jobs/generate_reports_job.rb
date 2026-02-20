# frozen_string_literal: true

# Scheduled job to generate export reports (CSV, JSON, Markdown, AI).
class GenerateReportsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("[GenerateReportsJob] Starting report generation...")

    ExporterService.export_csv
    ExporterService.export_json
    ExporterService.generate_reports

    Rails.logger.info("[GenerateReportsJob] Reports generated.")
  rescue StandardError => e
    Rails.logger.error("[GenerateReportsJob] Error: #{e.message}")
    raise
  end
end
