# frozen_string_literal: true

require "test_helper"

module Api
  class ReportControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "show returns consolidated report data" do
      get "/api/report", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert body.key?("market_context")
      assert body.key?("top_movers")
      assert body.key?("signals")
      assert body.key?("algorithmic")
    end

    test "requires authentication" do
      reset!
      get "/api/report", as: :json

      assert_response :redirect
    end
  end
end
