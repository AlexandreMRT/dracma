# frozen_string_literal: true

require "test_helper"

module Api
  class PortfoliosControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
      @portfolio = portfolios(:alice_default)
    end

    test "index returns portfolios" do
      get "/api/portfolios", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal 1, body["total"]
      assert_equal @portfolio.id, body.dig("portfolios", 0, "id")
    end

    test "show returns portfolio and performance" do
      get "/api/portfolios/#{@portfolio.id}", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal @portfolio.id, body.dig("portfolio", "id")
      assert body.key?("performance")
    end

    test "create makes new portfolio" do
      assert_difference -> { Portfolio.count }, 1 do
        post "/api/portfolios", params: { name: "Growth", is_default: true }, as: :json
      end

      assert_response :created
      body = JSON.parse(response.body)

      assert_equal "Growth", body.dig("portfolio", "name")
      assert body.dig("portfolio", "is_default")
    end

    test "update changes portfolio" do
      patch "/api/portfolios/#{@portfolio.id}", params: { name: "Renamed" }, as: :json

      assert_response :success
      assert_equal "Renamed", @portfolio.reload.name
    end

    test "destroy removes portfolio" do
      temp_portfolio = PortfolioService.create_portfolio(users(:alice), name: "Disposable")

      assert_difference -> { Portfolio.count }, -1 do
        delete "/api/portfolios/#{temp_portfolio.id}", as: :json
      end

      assert_response :success
      body = JSON.parse(response.body)

      assert body["deleted"]
    end

    test "performance rejects another users portfolio" do
      get "/api/portfolios/#{portfolios(:bob_default).id}/performance", as: :json

      assert_response :not_found
      body = JSON.parse(response.body)

      assert_equal "Portfolio not found", body["error"]
    end
  end
end
