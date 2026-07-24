# frozen_string_literal: true

require "test_helper"

class AssetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
  end

  test "index shows all assets" do
    get assets_path

    assert_response :success
  end

  test "index filters by type" do
    get assets_path(type: "stock")

    assert_response :success
  end

  test "show displays asset" do
    get asset_path(assets(:petr4))

    assert_response :success
  end

  test "show displays Graham valuation when computed" do
    get asset_path(assets(:petr4))

    assert_response :success
    assert_includes response.body, "Valuation (Graham)"
    assert_includes response.body, "Margin of Safety"
  end

  test "show notes missing fundamentals when Graham valuation is not computed" do
    get asset_path(assets(:aapl))

    assert_response :success
    assert_includes response.body, "Not enough fundamental data"
  end

  test "redirects to login when not authenticated" do
    reset!
    get assets_path

    assert_redirected_to login_path
  end
end
