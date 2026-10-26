# frozen_string_literal: true

class MarketDataRun < ApplicationRecord
  STATUSES = %w[running completed partial failed].freeze

  validates :provider, :status, :started_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :requested_count, :succeeded_count, :failed_count,
            numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(started_at: :desc) }

  def successful?
    status == "completed"
  end

  def partial?
    status == "partial"
  end
end
