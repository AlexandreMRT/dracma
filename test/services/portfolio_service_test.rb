# frozen_string_literal: true

require "test_helper"

class PortfolioServiceTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @portfolio = portfolios(:alice_default)
  end

  test "user_portfolios returns user's portfolios" do
    result = PortfolioService.user_portfolios(@alice)

    assert_includes result, @portfolio
  end

  test "find_portfolio returns nil for wrong user" do
    bob = users(:bob)

    assert_nil PortfolioService.find_portfolio(bob, @portfolio.id)
  end

  test "create_portfolio creates new portfolio" do
    assert_difference -> { @alice.portfolios.count }, 1 do
      PortfolioService.create_portfolio(@alice, name: "Test Port")
    end
  end

  test "create_portfolio with is_default resets others" do
    PortfolioService.create_portfolio(@alice, name: "New Default", is_default: true)
    @portfolio.reload

    assert_not @portfolio.is_default
  end

  test "delete_portfolio destroys it" do
    assert_difference -> { Portfolio.count }, -1 do
      PortfolioService.delete_portfolio(@portfolio)
    end
  end

  test "add_transaction creates transaction and position" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Empty")

    txn = PortfolioService.add_transaction(
      new_portfolio,
      ticker: "VALE3.SA",
      transaction_type: "buy",
      quantity: 50,
      price_brl: 60.0,
    )

    assert_predicate txn, :persisted?
    pos = PortfolioService.find_position(new_portfolio, "VALE3.SA")

    assert_not_nil pos
    assert_in_delta(50.0, pos.quantity)
    assert_in_delta(60.0, pos.avg_price_brl)
  end

  test "sell reduces position" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Sell Test")

    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "buy",
      quantity: 100, price_brl: 10.0)
    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "sell",
      quantity: 40, price_brl: 12.0)

    pos = PortfolioService.find_position(new_portfolio, "TEST")

    assert_in_delta(60.0, pos.quantity)
  end

  test "sell all removes position" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Full Sell")

    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "buy",
      quantity: 50, price_brl: 10.0)
    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "sell",
      quantity: 50, price_brl: 12.0)

    pos = PortfolioService.find_position(new_portfolio, "TEST")

    assert_nil pos
  end

  test "portfolio_performance returns hash" do
    perf = PortfolioService.portfolio_performance(@portfolio)

    assert_kind_of Hash, perf
    assert perf.key?(:total_invested)
    assert perf.key?(:positions)
  end
end
