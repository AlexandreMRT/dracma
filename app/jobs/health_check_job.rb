# frozen_string_literal: true

# Scheduled job that runs the data quality health check and logs the outcome.
# Scheduled daily on weekdays after quote fetching completes.
class HealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    report = DataHealthChecker.report

    case report[:status]
    when "critical"
      Rails.logger.error("[HealthCheckJob] status=critical totals=#{report[:totals]}")
    when "warning"
      Rails.logger.warn("[HealthCheckJob] status=warning totals=#{report[:totals]}")
    else
      Rails.logger.info("[HealthCheckJob] status=#{report[:status]} totals=#{report[:totals]}")
    end

    report
  rescue StandardError => e
    Rails.logger.error("[HealthCheckJob] Error: #{e.message}")
    raise
  end
end
