# frozen_string_literal: true

require "test_helper"

class HealthCheckJobTest < ActiveJob::TestCase
  test "enqueues on default queue" do
    assert_equal "default", HealthCheckJob.new.queue_name
  end

  test "runs the data health checker and returns its report" do
    fake_report = { status: "healthy", totals: { assets: 1, assets_with_quotes: 1 } }
    original = DataHealthChecker.method(:report)
    DataHealthChecker.define_singleton_method(:report) { fake_report }

    result = HealthCheckJob.perform_now

    assert_equal fake_report, result
  ensure
    DataHealthChecker.define_singleton_method(:report, original)
  end

  test "raises and logs when the checker fails" do
    original = DataHealthChecker.method(:report)
    DataHealthChecker.define_singleton_method(:report) { raise StandardError, "boom" }

    assert_raises(StandardError) { HealthCheckJob.perform_now }
  ensure
    DataHealthChecker.define_singleton_method(:report, original)
  end
end
