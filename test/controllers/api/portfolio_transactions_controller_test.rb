# frozen_string_literal: true

require "test_helper"

module Api
  class PortfolioTransactionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      login_as users(:alice)
      @portfolio = portfolios(:alice_default)
    end

    test "index returns transactions" do
      get "/api/portfolios/#{@portfolio.id}/transactions", as: :json

      assert_response :success
      body = JSON.parse(response.body)

      assert_equal 1, body["total"]
      assert_equal "PETR4.SA", body.dig("transactions", 0, "ticker")
    end

    test "create adds a transaction" do
      assert_difference -> { Transaction.count }, 1 do
        post "/api/portfolios/#{@portfolio.id}/transactions", params: {
          ticker: "VALE3.SA",
          transaction_type: "buy",
          quantity: "50",
          price_brl: "60.00",
          fees_brl: "0.0"
        }, as: :json
      end

      assert_response :created
      body = JSON.parse(response.body)

      assert_equal "VALE3.SA", body.dig("transaction", "ticker")
    end

    test "destroy removes a transaction" do
      transaction = transactions(:alice_buy_petr4)

      assert_difference -> { Transaction.count }, -1 do
        delete "/api/portfolios/#{@portfolio.id}/transactions/#{transaction.id}", as: :json
      end

      assert_response :success
      body = JSON.parse(response.body)

      assert body["deleted"]
    end

    test "destroy returns not found for another users portfolio" do
      delete "/api/portfolios/#{portfolios(:bob_default).id}/transactions/#{transactions(:bob_buy_aapl).id}", as: :json

      assert_response :not_found
      body = JSON.parse(response.body)

      assert_equal "Portfolio not found", body["error"]
    end
  end
end
