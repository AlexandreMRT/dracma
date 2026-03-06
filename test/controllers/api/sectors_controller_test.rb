# frozen_string_literal: true

require "test_helper"

module Api
  class SectorsControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
    end

    test "index returns sector performance" do
      get "/api/sectors", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal 2, body["total"]
      assert_equal %w[energy technology], body.fetch("sectors").map { |sector| sector["sector"] }.sort
    end

    test "requires authentication" do
      reset!
      get "/api/sectors", as: :json

      assert_response :redirect
    end
  end
end
