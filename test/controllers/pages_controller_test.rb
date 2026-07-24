# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "login page renders when not authenticated" do
    get login_path

    assert_response :success
  end

  test "login page uses oauth redirect host for auth request url when configured" do
    original = ENV["OAUTH_REDIRECT_URI"]
    ENV["OAUTH_REDIRECT_URI"] = "http://localhost:8000/auth/callback"

    get login_path

    assert_response :success
    assert_includes response.body, "href=\"http://localhost:8000/auth/google_oauth2\""
  ensure
    ENV["OAUTH_REDIRECT_URI"] = original
  end

  test "login page redirects to root when authenticated" do
    login_as users(:alice)
    get login_path

    assert_redirected_to root_path
  end
end
