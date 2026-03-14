# frozen_string_literal: true

require "test_helper"

class FetchQuotesJobTest < ActiveJob::TestCase
  test "enqueues on default queue" do
    assert_equal "default", FetchQuotesJob.new.queue_name
  end

  test "calls QuoteFetcher#fetch_all" do
    called = false
    fetcher = Object.new
    fetcher.define_singleton_method(:fetch_all) { called = true }
    original_new = QuoteFetcher.method(:new)

    QuoteFetcher.define_singleton_method(:new) { fetcher }
    FetchQuotesJob.perform_now

    assert called
  ensure
    QuoteFetcher.define_singleton_method(:new, original_new)
  end
end
