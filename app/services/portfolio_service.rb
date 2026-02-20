# frozen_string_literal: true
# typed: true

# Portfolio management: CRUD + position recalculation + performance.
# Ported from Python portfolio.py.
module PortfolioService
  extend T::Sig

  # === Portfolio CRUD ===

  sig { params(user: T.untyped).returns(T.untyped) }
  def self.user_portfolios(user)
    user.portfolios.order(is_default: :desc, created_at: :asc)
  end

  sig { params(user: T.untyped, portfolio_id: T.untyped).returns(T.untyped) }
  def self.find_portfolio(user, portfolio_id)
    user.portfolios.find_by(id: portfolio_id)
  end

  sig { params(user: T.untyped, name: String, is_default: T::Boolean).returns(T.untyped) }
  def self.create_portfolio(user, name:, is_default: false)
    user.portfolios.update_all(is_default: false) if is_default
    user.portfolios.create!(name: name, is_default: is_default)
  end

  sig { params(portfolio: T.untyped, name: T.nilable(String), is_default: T.nilable(T::Boolean)).returns(T.untyped) }
  def self.update_portfolio(portfolio, name: nil, is_default: nil)
    if is_default
      portfolio.user.portfolios.update_all(is_default: false)
    end
    attrs = {}
    attrs[:name] = name if name
    attrs[:is_default] = is_default unless is_default.nil?
    portfolio.update!(attrs)
    portfolio
  end

  sig { params(portfolio: T.untyped).void }
  def self.delete_portfolio(portfolio)
    portfolio.destroy!
  end

  # === Positions ===

  sig { params(portfolio: T.untyped).returns(T.untyped) }
  def self.positions(portfolio)
    portfolio.positions.order(:ticker)
  end

  sig { params(portfolio: T.untyped, ticker: String).returns(T.untyped) }
  def self.find_position(portfolio, ticker)
    portfolio.positions.find_by(ticker: ticker.upcase)
  end

  # === Transactions ===

  sig { params(portfolio: T.untyped, limit: Integer).returns(T.untyped) }
  def self.transactions(portfolio, limit: 100)
    portfolio.transactions.order(transaction_date: :desc).limit(limit)
  end

  sig { params(portfolio: T.untyped, ticker: String).returns(T.untyped) }
  def self.ticker_transactions(portfolio, ticker)
    portfolio.transactions.where(ticker: ticker.upcase).order(transaction_date: :desc)
  end

  sig do
    params(
      portfolio: T.untyped, ticker: String, transaction_type: String,
      quantity: Numeric, price_brl: Numeric, fees_brl: Numeric,
      transaction_date: T.nilable(T.any(Time, Date)), notes: T.nilable(String)
    ).returns(T.untyped)
  end
  def self.add_transaction(portfolio, ticker:, transaction_type:, quantity:, price_brl:,
                           fees_brl: 0.0, transaction_date: nil, notes: nil)
    transaction_date ||= Time.current
    total_brl = (quantity * price_brl) + fees_brl

    txn = portfolio.transactions.create!(
      ticker: ticker.upcase,
      transaction_type: transaction_type,
      quantity: quantity,
      price_brl: price_brl,
      total_brl: total_brl,
      fees_brl: fees_brl,
      transaction_date: transaction_date,
    )

    update_position_from_transaction(portfolio, ticker, txn)
    txn
  end

  sig { params(portfolio: T.untyped, transaction_id: T.untyped).returns(T::Boolean) }
  def self.delete_transaction(portfolio, transaction_id)
    txn = portfolio.transactions.find_by(id: transaction_id)
    return false unless txn

    ticker = txn.ticker
    txn.destroy!
    recalculate_position(portfolio, ticker)
    true
  end

  # === Position recalc ===

  sig { params(portfolio: T.untyped, ticker: String, txn: T.untyped).void }
  def self.update_position_from_transaction(portfolio, ticker, txn)
    pos = find_position(portfolio, ticker)

    case txn.transaction_type
    when "buy"
      if pos
        total_cost = (pos.quantity * pos.avg_price_brl) + txn.total_brl
        new_qty = pos.quantity + txn.quantity
        pos.update!(
          avg_price_brl: new_qty.positive? ? total_cost / new_qty : 0,
          quantity: new_qty,
        )
      else
        portfolio.positions.create!(
          ticker: ticker.upcase,
          quantity: txn.quantity,
          avg_price_brl: txn.price_brl,
        )
      end
    when "sell"
      return unless pos

      pos.quantity -= txn.quantity
      if pos.quantity <= 0
        pos.destroy!
        return
      end
      pos.save!
    when "dividend", "split", "merge"
      # no position change
    end
  end

  sig { params(portfolio: T.untyped, ticker: String).void }
  def self.recalculate_position(portfolio, ticker)
    pos = find_position(portfolio, ticker)
    pos&.destroy!

    portfolio.transactions.where(ticker: ticker.upcase)
             .order(:transaction_date).each do |txn|
      update_position_from_transaction(portfolio, ticker, txn)
    end
  end

  # === Performance ===

  sig { params(position: T.untyped).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def self.position_performance(position)
    asset = Asset.find_by(ticker: position.ticker)
    return nil unless asset

    latest = asset.quotes.order(quote_date: :desc).first
    return nil unless latest

    current_price = latest.price_brl
    current_value = position.quantity * current_price
    invested      = position.quantity * position.avg_price_brl
    pnl           = current_value - invested
    pnl_pct       = invested.positive? ? ((current_value / invested) - 1) * 100 : 0

    {
      ticker: position.ticker,
      quantity: position.quantity,
      avg_price: position.avg_price_brl,
      current_price: current_price,
      invested_value: invested,
      current_value: current_value,
      profit_loss: pnl,
      profit_loss_pct: pnl_pct.round(2)
    }
  end

  sig { params(portfolio: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
  def self.portfolio_performance(portfolio)
    total_invested = 0.0
    total_current  = 0.0
    pos_data = []

    portfolio.positions.each do |pos|
      perf = position_performance(pos)
      next unless perf

      pos_data << perf
      total_invested += perf[:invested_value]
      total_current  += perf[:current_value]
    end

    pnl = total_current - total_invested
    pnl_pct = total_invested.positive? ? ((total_current / total_invested) - 1) * 100 : 0

    dividends = portfolio.transactions
                         .where(transaction_type: :dividend)
                         .sum(:total_brl)

    {
      portfolio_id: portfolio.id,
      total_invested: total_invested.round(2),
      total_current_value: total_current.round(2),
      total_profit_loss: pnl.round(2),
      total_profit_loss_pct: pnl_pct.round(2),
      dividend_income: dividends.round(2),
      total_return: (pnl + dividends).round(2),
      total_return_pct: total_invested.positive? ? (((pnl + dividends) / total_invested) * 100).round(2) : 0,
      positions_count: pos_data.size,
      positions: pos_data
    }
  end
end
