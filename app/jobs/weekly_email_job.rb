# frozen_string_literal: true

# Sends the weekly market summary email to all registered users.
# Scheduled every Friday at 18:30 BRT (after market close).
class WeeklyEmailJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("[WeeklyEmailJob] Starting weekly email delivery...")

    count = 0
    User.find_each do |user|
      WeeklyReportMailer.weekly_summary(user).deliver_later
      count += 1
    end

    Rails.logger.info("[WeeklyEmailJob] Enqueued #{count} weekly summary emails.")
  rescue StandardError => e
    Rails.logger.error("[WeeklyEmailJob] Error: #{e.message}")
    raise
  end
end
