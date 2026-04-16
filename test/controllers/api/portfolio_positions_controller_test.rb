# frozen_string_literal: true

require "test_helper"

module Api
  class PortfolioPositionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
      @portfolio = portfolios(:alice_default)
    end

    test "index returns positions with performance" do
      get "/api/portfolios/#{@portfolio.id}/positions", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal 1, body["total"]
      assert_equal "PETR4.SA", body.dig("positions", 0, "ticker")
      assert_equal "BTG Pactual", body.dig("positions", 0, "broker")
      assert body.dig("positions", 0, "performance")
    end

    test "index rejects another users portfolio" do
      get "/api/portfolios/#{portfolios(:bob_default).id}/positions", as: :json

      assert_response :not_found
      body = JSON.parse(response.body)

      assert_equal "Portfolio not found", body["error"]
    end
  end
end
