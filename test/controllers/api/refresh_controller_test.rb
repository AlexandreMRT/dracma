# frozen_string_literal: true

require "test_helper"

module Api
  class RefreshControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      login_as users(:alice)
      clear_enqueued_jobs
    end

    teardown do
      clear_enqueued_jobs
    end

    test "create enqueues a quote refresh" do
      assert_enqueued_with(job: FetchQuotesJob) do
        post "/api/refresh", as: :json
      end

      assert_response :accepted
      body = JSON.parse(response.body)

      assert body["enqueued"]
      assert body.key?("job_id")
    end

    test "requires authentication" do
      reset!
      post "/api/refresh", as: :json

      assert_response :redirect
    end
  end
end
