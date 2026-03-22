# frozen_string_literal: true

# Sends a weekly market summary email to a user.
# Includes top weekly movers, active signals, and portfolio performance.
class WeeklyReportMailer < ApplicationMailer
  def weekly_summary(user)
    @user = user
    @week_label = Date.current.strftime("Week of %B %-d, %Y")

    rows = ExporterService.latest_rows
    stock_rows = rows.select { |r| r[:tipo].in?(%w[stock us_stock]) }

    @gainers = stock_rows.select { |r| r[:var_1w] }.max_by(5) { |r| r[:var_1w] }
    @losers  = stock_rows.select { |r| r[:var_1w] }.min_by(5) { |r| r[:var_1w] }
    @bullish = stock_rows.select { |r| r[:signal_summary] == "bullish" }.first(8)
    @bearish = stock_rows.select { |r| r[:signal_summary] == "bearish" }.first(8)

    @ibov_ytd  = rows.find { |r| r[:ibov_change_ytd] }&.dig(:ibov_change_ytd)
    @sp500_ytd = rows.find { |r| r[:sp500_change_ytd] }&.dig(:sp500_change_ytd)
    @usd_brl   = rows.find { |r| r[:tipo] == "currency" }&.dig(:preco_brl)

    @portfolios = build_portfolio_summaries(user)

    mail(to: user.email, subject: "[Dracma] Weekly Market Summary — #{@week_label}")
  end

  private

  def build_portfolio_summaries(user)
    user.portfolios.order(is_default: :desc, created_at: :asc).filter_map do |portfolio|
      perf = PortfolioService.portfolio_performance(portfolio)
      next if perf.nil? || perf[:positions_count].zero?

      { portfolio: portfolio, performance: perf }
    end
  end
end
