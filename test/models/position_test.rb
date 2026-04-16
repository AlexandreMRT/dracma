require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "valid position" do
    assert_predicate positions(:alice_petr4), :valid?
  end

  test "belongs to portfolio" do
    assert_equal portfolios(:alice_default), positions(:alice_petr4).portfolio
  end

  test "validates quantity is positive" do
    pos = positions(:alice_petr4)
    pos.quantity = -1

    assert_not pos.valid?
  end

  test "validates broker presence" do
    pos = positions(:alice_petr4)
    pos.broker = ""

    assert_not pos.valid?
  end

  test "same ticker different broker is allowed" do
    existing = positions(:alice_petr4)
    new_pos = existing.portfolio.positions.build(
      ticker: existing.ticker,
      broker: "Inter",
      quantity: 10,
      avg_price_brl: 30.0
    )

    assert_predicate new_pos, :valid?
  end

  test "same ticker same broker is rejected" do
    existing = positions(:alice_petr4)
    new_pos = existing.portfolio.positions.build(
      ticker: existing.ticker,
      broker: existing.broker,
      quantity: 10,
      avg_price_brl: 30.0
    )

    assert_not new_pos.valid?
  end
end
