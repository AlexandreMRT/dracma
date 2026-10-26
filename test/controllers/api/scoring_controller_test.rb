# frozen_string_literal: true

require "test_helper"

module Api
  class ScoringControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index returns scoring data" do
      get api_scoring_path, as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_empty body["watchlist"]
      assert_empty body["avoid_list"]
      assert_equal "disabled", body.dig("recommendation_policy", "status")
    end

    test "requires authentication" do
      reset!
      get api_scoring_path, as: :json

      assert_response :redirect
    end
  end
end
