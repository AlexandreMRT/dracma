# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "login page renders when not authenticated" do
    get login_path

    assert_response :success
  end

  test "login page redirects to root when authenticated" do
    login_as users(:alice)
    get login_path

    assert_redirected_to root_path
  end
end
