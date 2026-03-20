# frozen_string_literal: true

require "test_helper"

module Api
  class NewsControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index filters news by sentiment" do
      get "/api/news", params: { sentiment: "positive" }, as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal "positive", body["sentiment"]
      assert_equal 1, body["total"]
      assert_equal "PETR4", body.dig("news", 0, "ticker")
    end

    test "index rejects invalid sentiment" do
      get "/api/news", params: { sentiment: "bullish" }, as: :json

      assert_response :bad_request
      body = JSON.parse(response.body)

      assert_equal "Invalid sentiment", body["error"]
    end
  end
end
