require "test_helper"

class WatchlistTest < ActiveSupport::TestCase
  test "valid watchlist" do
    assert_predicate watchlists(:alice_petr4), :valid?
  end

  test "belongs to user" do
    assert_equal users(:alice), watchlists(:alice_petr4).user
  end

  test "unique ticker per user" do
    wl = Watchlist.new(user: users(:alice), ticker: watchlists(:alice_petr4).ticker)

    assert_not wl.valid?
  end
end
