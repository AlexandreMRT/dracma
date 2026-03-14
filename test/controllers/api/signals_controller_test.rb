# frozen_string_literal: true

require "test_helper"

module Api
  class SignalsControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index returns signal data" do
      get api_signals_path, as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal [ "AAPL" ], body["bullish"]
      assert_empty body["bearish"]
      assert_empty body["rsi_oversold"]
      assert_empty body["rsi_overbought"]
      assert_empty body["volume_spike"]
    end

    test "requires authentication" do
      reset!
      get api_signals_path, as: :json

      assert_response :redirect
    end
  end
end
