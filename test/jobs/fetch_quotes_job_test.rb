# frozen_string_literal: true

require "test_helper"

class FetchQuotesJobTest < ActiveJob::TestCase
  test "enqueues on default queue" do
    assert_equal "default", FetchQuotesJob.new.queue_name
  end

  test "calls QuoteFetcher#fetch_all" do
    called = false
    QuoteFetcher.define_method(:fetch_all) { called = true }
    FetchQuotesJob.perform_now

    assert called
  ensure
    QuoteFetcher.define_method(:fetch_all) { raise "not stubbed" }
  end
end
