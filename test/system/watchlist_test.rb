# frozen_string_literal: true

require "application_system_test_case"

class WatchlistTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:alice)
    visit watchlists_path
  end

  test "watchlist page shows page heading" do
    assert_text "Watchlist"
  end

  test "watchlist shows existing ticker entries" do
    # Fixtures: alice_petr4 and alice_aapl
    assert_text "PETR4.SA"
    assert_text "AAPL"
  end

  test "watchlist page has ticker input and add button" do
    assert_selector "input[name='ticker']"
    assert_selector "input[value='Add']"
  end

  test "adding a new ticker creates a watchlist entry" do
    fill_in "ticker", with: "VALE3.SA"
    click_on "Add"

    assert_current_path watchlists_path
    assert_text "VALE3.SA"
  end

  test "removing a ticker deletes the entry" do
    assert_text "PETR4.SA"

    within "#watchlist_#{watchlists(:alice_petr4).id}" do
      accept_confirm { click_on "Remove" }
    end

    assert_no_text "PETR4.SA"
  end

  test "watchlist title is set correctly" do
    assert_title "Watchlist — Dracma"
  end
end
