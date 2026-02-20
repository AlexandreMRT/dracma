require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "valid portfolio" do
    assert portfolios(:alice_default).valid?
  end

  test "requires name" do
    p = Portfolio.new(user: users(:alice))
    assert_not p.valid?
    assert_includes p.errors[:name], "can't be blank"
  end

  test "belongs to user" do
    assert_equal users(:alice), portfolios(:alice_default).user
  end

  test "has many positions" do
    assert_respond_to portfolios(:alice_default), :positions
  end

  test "has many transactions" do
    assert_respond_to portfolios(:alice_default), :transactions
  end
end
