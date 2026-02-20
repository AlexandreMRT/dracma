# frozen_string_literal: true

require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
  end

  test "index shows portfolios" do
    get portfolios_path
    assert_response :success
  end

  test "new renders form" do
    get new_portfolio_path
    assert_response :success
  end

  test "create makes new portfolio" do
    assert_difference -> { Portfolio.count }, 1 do
      post portfolios_path, params: { portfolio: { name: "New Port", is_default: "0" } }
    end
    assert_redirected_to portfolio_path(Portfolio.last)
  end

  test "show displays portfolio" do
    get portfolio_path(portfolios(:alice_default))
    assert_response :success
  end

  test "edit renders form" do
    get edit_portfolio_path(portfolios(:alice_default))
    assert_response :success
  end

  test "update changes portfolio" do
    patch portfolio_path(portfolios(:alice_default)), params: { portfolio: { name: "Renamed" } }
    assert_redirected_to portfolio_path(portfolios(:alice_default))
    assert_equal "Renamed", portfolios(:alice_default).reload.name
  end

  test "destroy removes portfolio" do
    assert_difference -> { Portfolio.count }, -1 do
      delete portfolio_path(portfolios(:alice_default))
    end
    assert_redirected_to portfolios_path
  end

  test "cannot access other user's portfolio" do
    get portfolio_path(portfolios(:bob_default))
    assert_redirected_to portfolios_path
  end
end
