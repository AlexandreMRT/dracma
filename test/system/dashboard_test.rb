# frozen_string_literal: true

require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:alice)
  end

  test "dashboard page loads at root path" do
    assert_current_path root_path
    assert_text "IBOV YTD"
  end

  test "dashboard shows market overview cards" do
    assert_text "IBOV YTD"
    assert_text "S&P 500 YTD"
    assert_text "USD/BRL"
  end

  test "dashboard shows top movers sections" do
    assert_text "Top Gainers"
    assert_text "Top Losers"
  end

  test "dashboard shows signals section" do
    assert_text "Bullish Signals"
    assert_text "Bearish Signals"
  end

  test "dashboard shows fixture stock data" do
    # PETR4 has change_1d: 1.58 (top gainer), AAPL has signal_summary: bullish
    assert_text "PETR4"
    assert_text "AAPL"
  end

  test "dashboard title is set correctly" do
    assert_title "Dashboard — Dracma"
  end
end
