# frozen_string_literal: true

require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
    @portfolio = portfolios(:alice_default)
  end

  test "index shows positions" do
    get portfolio_positions_path(@portfolio)

    assert_response :success
  end

  test "show displays position" do
    position = positions(:alice_petr4)
    get portfolio_position_path(@portfolio, position.id)

    assert_response :success
  end

  test "show redirects for unknown position" do
    get portfolio_position_path(@portfolio, 0)

    assert_redirected_to portfolio_positions_path(@portfolio)
  end

  test "redirects to login when not authenticated" do
    reset!
    get portfolio_positions_path(@portfolio)

    assert_redirected_to login_path
  end
end
