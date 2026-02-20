require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "valid transaction" do
    assert_predicate transactions(:alice_buy_petr4), :valid?
  end

  test "belongs to portfolio" do
    assert_equal portfolios(:alice_default), transactions(:alice_buy_petr4).portfolio
  end

  test "buy enum" do
    txn = transactions(:alice_buy_petr4)

    assert_predicate txn, :transaction_type_buy?
  end
end
