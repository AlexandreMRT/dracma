# frozen_string_literal: true

require "test_helper"

class WatchlistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
  end

  test "index shows watchlists" do
    get watchlists_path

    assert_response :success
  end

  test "create adds ticker to watchlist" do
    assert_difference -> { users(:alice).watchlists.count }, 1 do
      post watchlists_path, params: { ticker: "VALE3.SA" }
    end
    assert_redirected_to watchlists_path
  end

  test "destroy removes watchlist entry" do
    wl = watchlists(:alice_petr4)
    assert_difference -> { Watchlist.count }, -1 do
      delete watchlist_path(wl)
    end
    assert_redirected_to watchlists_path
  end
end
