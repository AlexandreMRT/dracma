# frozen_string_literal: true

require "test_helper"

module Api
  class WatchlistsControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index returns watchlists" do
      get "/api/watchlist", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal 2, body["total"]
      assert_equal %w[AAPL PETR4.SA], body.fetch("watchlists").map { |watchlist| watchlist["ticker"] }.sort
    end

    test "create adds a watchlist entry" do
      assert_difference -> { users(:alice).watchlists.count }, 1 do
        post "/api/watchlist", params: { ticker: "VALE3.SA", notes: "Watch closely" }, as: :json
      end

      assert_response :created
      body = JSON.parse(response.body)

      assert_equal "VALE3.SA", body.dig("watchlist", "ticker")
      assert_equal "Watch closely", body.dig("watchlist", "notes")
    end

    test "destroy removes a watchlist entry by ticker" do
      assert_difference -> { Watchlist.count }, -1 do
        delete "/api/watchlist/AAPL", as: :json
      end

      assert_response :success
      body = JSON.parse(response.body)

      assert body["deleted"]
    end
  end
end
