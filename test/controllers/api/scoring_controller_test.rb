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

      assert body.key?("watchlist")
      assert body.key?("avoid_list")
    end

    test "requires authentication" do
      reset!
      get api_scoring_path, as: :json

      assert_response :redirect
    end
  end
end
