# frozen_string_literal: true

require "test_helper"

module Api
  class MoversControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index returns top movers for a period" do
      get "/api/movers", params: { period: "1d", limit: 1 }, as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal "1d", body["period"]
      assert_equal 1, body.fetch("gainers").size
      assert_equal "PETR4", body.dig("gainers", 0, "ticker")
      assert_equal "AAPL", body.dig("losers", 0, "ticker")
    end

    test "index rejects invalid period" do
      get "/api/movers", params: { period: "quarter" }, as: :json

      assert_response :bad_request
      body = JSON.parse(response.body)

      assert_equal "Invalid period", body["error"]
    end
  end
end
