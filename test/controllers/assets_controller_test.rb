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

  test "redirects to login when not authenticated" do
    reset!
    get assets_path

    assert_redirected_to login_path
  end
end
