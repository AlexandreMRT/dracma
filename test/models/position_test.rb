require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "valid position" do
    assert positions(:alice_petr4).valid?
  end

  test "belongs to portfolio" do
    assert_equal portfolios(:alice_default), positions(:alice_petr4).portfolio
  end

  test "validates quantity is positive" do
    pos = positions(:alice_petr4)
    pos.quantity = -1
    assert_not pos.valid?
  end
end
