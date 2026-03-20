# frozen_string_literal: true

require "test_helper"

module Api
  class HealthControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "data returns health summary" do
      get "/api/health/data", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_includes %w[healthy warning critical], body["status"]
      assert body.key?("generated_at")
      assert body.key?("totals")
      assert body.key?("samples")
    end

    test "requires authentication" do
      reset!
      get "/api/health/data", as: :json

      assert_response :redirect
    end
  end
end
