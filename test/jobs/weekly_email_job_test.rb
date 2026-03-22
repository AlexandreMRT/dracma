# frozen_string_literal: true

require "test_helper"

class WeeklyEmailJobTest < ActiveJob::TestCase
  setup do
    @orig_latest_rows = ExporterService.method(:latest_rows)
    ExporterService.define_singleton_method(:latest_rows) { |**| [] }
  end

  teardown do
    ExporterService.define_singleton_method(:latest_rows, @orig_latest_rows)
  end

  test "enqueues on default queue" do
    assert_equal "default", WeeklyEmailJob.new.queue_name
  end

  test "enqueues one email per user" do
    assert_enqueued_jobs User.count, only: ActionMailer::MailDeliveryJob do
      WeeklyEmailJob.perform_now
    end
  end
end
