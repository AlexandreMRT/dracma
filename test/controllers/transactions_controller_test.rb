# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    login_as users(:alice)
    @portfolio = portfolios(:alice_default)
  end

  test "index shows transactions" do
    get portfolio_transactions_path(@portfolio)
    assert_response :success
  end

  test "create adds transaction" do
    assert_difference -> { Transaction.count }, 1 do
      post portfolio_transactions_path(@portfolio), params: {
        transaction: {
          ticker: "VALE3.SA",
          transaction_type: "buy",
          quantity: "50",
          price_brl: "60.00",
          fees_brl: "0.00",
        },
      }
    end
    assert_redirected_to portfolio_transactions_path(@portfolio)
  end

  test "destroy removes transaction" do
    txn = transactions(:alice_buy_petr4)
    assert_difference -> { Transaction.count }, -1 do
      delete portfolio_transaction_path(@portfolio, txn)
    end
    assert_redirected_to portfolio_transactions_path(@portfolio)
  end
end
