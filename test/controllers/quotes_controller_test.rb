# frozen_string_literal: true

require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
  end

  test "index shows latest quotes" do
    get quotes_path

    assert_response :success
  end

  test "index filters by date" do
    get quotes_path(date: "2026-02-10")

    assert_response :success
  end

  test "redirects to login when not authenticated" do
    reset!
    get quotes_path

    assert_redirected_to login_path
  end
end
