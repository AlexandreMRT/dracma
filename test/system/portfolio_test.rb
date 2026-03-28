# frozen_string_literal: true

require "application_system_test_case"

class PortfolioTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:alice)
    visit portfolios_path
  end

  test "portfolios index shows page heading" do
    assert_text "Portfolios"
  end

  test "portfolios index shows existing portfolio" do
    # Fixture: alice_default named 'Main Portfolio'
    assert_text "Main Portfolio"
  end

  test "portfolios index has new portfolio link" do
    assert_selector "a", text: "New Portfolio"
  end

  test "creating a new portfolio" do
    click_on "New Portfolio"

    assert_text "New Portfolio"
    fill_in "portfolio_name", with: "Tech Stocks"
    click_on "Create"

    assert_text "Tech Stocks"
  end

  test "viewing a portfolio shows performance and positions" do
    click_on "Main Portfolio"

    assert_text "Main Portfolio"
    assert_text "Invested"
    assert_text "Current Value"
  end

  test "editing a portfolio changes its name" do
    click_on "Main Portfolio"
    click_on "Edit"

    fill_in "portfolio_name", with: "Renamed Portfolio"
    click_on "Update"

    assert_text "Renamed Portfolio"
  end

  test "cannot view another user's portfolio" do
    # Navigating directly to Bob's portfolio should redirect away
    visit portfolio_path(portfolios(:bob_default))

    assert_current_path portfolios_path
  end

  test "deleting a portfolio removes it from the list" do
    portfolio_name = "Disposable Portfolio"
    click_on "New Portfolio"
    fill_in "portfolio_name", with: portfolio_name
    click_on "Create"

    # Create redirects to the show page — click Edit directly from there
    click_on "Edit"

    accept_confirm do
      click_on "Delete Portfolio"
    end

    assert_current_path portfolios_path
    assert_no_text portfolio_name
  end

  test "portfolio index title is set correctly" do
    assert_title "Portfolios — Dracma"
  end
end
