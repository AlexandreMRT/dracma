# frozen_string_literal: true

require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "login page shows google sign in button" do
    visit login_path

    assert_text "Sign in with Google"
    assert_selector "a[href='/auth/google_oauth2']"
  end

  test "unauthenticated visit to dashboard redirects to login" do
    visit root_path

    assert_current_path login_path
  end

  test "signing in redirects to dashboard" do
    sign_in_as users(:alice)

    assert_current_path root_path
  end

  test "signed-in layout shows navigation and user name" do
    sign_in_as users(:alice)

    assert_text "Dracma"
    assert_text users(:alice).name
    assert_text "Watchlist"
    assert_text "Portfolios"
  end

  test "logging out returns to login page" do
    sign_in_as users(:alice)
    click_on "Logout"

    assert_current_path login_path
    assert_text "Sign in with Google"
  end

  test "after logout dashboard is inaccessible" do
    sign_in_as users(:alice)
    click_on "Logout"
    visit root_path

    assert_current_path login_path
  end

  test "login page shows app name" do
    visit login_path

    assert_text "Dracma"
  end
end
