# frozen_string_literal: true

require "test_helper"

module Api
  class QuotesControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index returns json quotes" do
      get api_quotes_path, as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert body.key?("total")
      assert body.key?("quotes")
    end

    test "index filters by date" do
      get api_quotes_path(date: "2026-02-10"), as: :json

      assert_response :success
    end

    test "index rejects invalid date" do
      get api_quotes_path(date: "not-a-date"), as: :json

      assert_response :bad_request
      body = JSON.parse(response.body)

      assert_equal "Invalid date format", body["error"]
    end

    test "show returns asset detail by ticker" do
      get "/api/quotes/PETR4", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal "PETR4", body.dig("asset", "ticker")
      assert_equal "neutral", body.dig("signals", "summary")
      assert_equal 1, body.fetch("history").size
    end

    test "show returns not found for missing asset" do
      get "/api/quotes/UNKNOWN", as: :json

      assert_response :not_found
      body = JSON.parse(response.body)

      assert_equal "Asset not found", body["error"]
    end

    test "requires authentication" do
      reset!
      get api_quotes_path, as: :json

      assert_response :redirect
    end
  end
end
