# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not authenticated" do
    get root_path
    assert_redirected_to login_path
  end

  test "shows dashboard when authenticated" do
    login_as users(:alice)
    get root_path
    assert_response :success
  end
end
