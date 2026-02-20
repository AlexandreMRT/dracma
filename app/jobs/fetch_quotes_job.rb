# frozen_string_literal: true

# Scheduled job to fetch all quotes.
# Enqueued via Solid Queue recurring schedule.
class FetchQuotesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("[FetchQuotesJob] Starting quote fetch...")
    QuoteFetcher.fetch_all
    Rails.logger.info("[FetchQuotesJob] Quote fetch complete.")
  rescue StandardError => e
    Rails.logger.error("[FetchQuotesJob] Error: #{e.message}")
    raise # let Solid Queue retry
  end
end
