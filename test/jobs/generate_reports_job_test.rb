# frozen_string_literal: true

require "test_helper"

class GenerateReportsJobTest < ActiveJob::TestCase
  test "enqueues on default queue" do
    assert_equal "default", GenerateReportsJob.new.queue_name
  end

  test "calls exporter service methods" do
    csv_called = false
    json_called = false
    reports_called = false

    orig_csv = ExporterService.method(:export_csv)
    orig_json = ExporterService.method(:export_json)
    orig_reports = ExporterService.method(:generate_reports)

    ExporterService.define_singleton_method(:export_csv) { |**| csv_called = true; nil }
    ExporterService.define_singleton_method(:export_json) { |**| json_called = true; nil }
    ExporterService.define_singleton_method(:generate_reports) { reports_called = true; nil }

    GenerateReportsJob.perform_now

    assert csv_called
    assert json_called
    assert reports_called
  ensure
    ExporterService.define_singleton_method(:export_csv, orig_csv)
    ExporterService.define_singleton_method(:export_json, orig_json)
    ExporterService.define_singleton_method(:generate_reports, orig_reports)
  end
end
