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
      broker: "BTG Pactual",
    )

    assert_predicate txn, :persisted?
    pos = PortfolioService.find_position(new_portfolio, "VALE3.SA", broker: "BTG Pactual")

    assert_not_nil pos
    assert_in_delta(50.0, pos.quantity)
    assert_in_delta(60.0, pos.avg_price_brl)
    assert_equal "BTG Pactual", pos.broker
  end

  test "sell reduces position" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Sell Test")

    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "buy",
      quantity: 100, price_brl: 10.0, broker: "Inter")
    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "sell",
      quantity: 40, price_brl: 12.0, broker: "Inter")

    pos = PortfolioService.find_position(new_portfolio, "TEST", broker: "Inter")

    assert_in_delta(60.0, pos.quantity)
  end

  test "sell all removes position" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Full Sell")

    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "buy",
      quantity: 50, price_brl: 10.0, broker: "Inter")
    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "sell",
      quantity: 50, price_brl: 12.0, broker: "Inter")

    pos = PortfolioService.find_position(new_portfolio, "TEST", broker: "Inter")

    assert_nil pos
  end

  test "same ticker different brokers creates separate positions" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Multi Broker")

    PortfolioService.add_transaction(new_portfolio, ticker: "PETR4.SA", transaction_type: "buy",
      quantity: 100, price_brl: 35.0, broker: "BTG Pactual")
    PortfolioService.add_transaction(new_portfolio, ticker: "PETR4.SA", transaction_type: "buy",
      quantity: 50, price_brl: 36.0, broker: "Inter")

    btg_pos = PortfolioService.find_position(new_portfolio, "PETR4.SA", broker: "BTG Pactual")
    inter_pos = PortfolioService.find_position(new_portfolio, "PETR4.SA", broker: "Inter")

    assert_not_nil btg_pos
    assert_not_nil inter_pos
    assert_in_delta(100.0, btg_pos.quantity)
    assert_in_delta(50.0, inter_pos.quantity)
    assert_equal 2, new_portfolio.positions.where(ticker: "PETR4.SA").count
  end

  test "delete_transaction recalculates position for correct broker" do
    new_portfolio = PortfolioService.create_portfolio(@alice, name: "Delete Test")

    PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "buy",
      quantity: 100, price_brl: 10.0, broker: "BTG Pactual")
    txn2 = PortfolioService.add_transaction(new_portfolio, ticker: "TEST", transaction_type: "buy",
      quantity: 50, price_brl: 10.0, broker: "Inter")

    PortfolioService.delete_transaction(new_portfolio, txn2.id)

    btg_pos = PortfolioService.find_position(new_portfolio, "TEST", broker: "BTG Pactual")
    inter_pos = PortfolioService.find_position(new_portfolio, "TEST", broker: "Inter")

    assert_not_nil btg_pos
    assert_in_delta(100.0, btg_pos.quantity)
    assert_nil inter_pos
  end

  test "portfolio_performance returns hash" do
    perf = PortfolioService.portfolio_performance(@portfolio)

    assert_kind_of Hash, perf
    assert perf.key?(:total_invested)
    assert perf.key?(:positions)
  end
end
