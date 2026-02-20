require "test_helper"

class QuoteTest < ActiveSupport::TestCase
  test "valid quote" do
    assert quotes(:petr4_today).valid?
  end

  test "belongs to asset" do
    assert_equal assets(:petr4), quotes(:petr4_today).asset
  end

  test "requires price_brl" do
    q = Quote.new(asset: assets(:petr4), quote_date: Date.new(2026, 3, 1))
    assert_not q.valid?
    assert_includes q.errors[:price_brl], "can't be blank"
  end
end
