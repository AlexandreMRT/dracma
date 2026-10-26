# frozen_string_literal: true

require "test_helper"

class PortfolioRiskServiceTest < ActiveSupport::TestCase
  setup do
    @portfolio = portfolios(:alice_default)
  end

  test "reports position and sector concentration" do
    risk = PortfolioRiskService.analyze(@portfolio, health: { status: "healthy" })

    assert_equal "concentrated", risk[:status]
    assert_includes risk[:warnings], "PETR4.SA is 100.0% of the portfolio"
    assert_equal "energy", risk.dig(:by_sector, 0, :name)
    assert_in_delta 100.0, risk.dig(:by_sector, 0, :percentage)
  end

  test "reports an empty portfolio as balanced" do
    @portfolio.positions.delete_all

    risk = PortfolioRiskService.analyze(@portfolio, health: { status: "healthy" })

    assert_equal "balanced", risk[:status]
    assert_empty risk[:warnings]
    assert_in_delta 0.0, risk.dig(:totals, :current_value)
  end
end
