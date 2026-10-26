# frozen_string_literal: true

# Portfolio management: CRUD + position recalculation + performance.
# Ported from Python portfolio.py.
module PortfolioService
  # === Portfolio CRUD ===

  def self.user_portfolios(user)
    user.portfolios.order(is_default: :desc, created_at: :asc)
  end

  def self.find_portfolio(user, portfolio_id)
    user.portfolios.find_by(id: portfolio_id)
  end

  def self.create_portfolio(user, name:, is_default: false)
    user.portfolios.update_all(is_default: false) if is_default
    user.portfolios.create!(name: name, is_default: is_default)
  end

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

  def self.delete_portfolio(portfolio)
    portfolio.destroy!
  end

  # === Positions ===

  def self.positions(portfolio)
    portfolio.positions.order(:ticker)
  end

  def self.find_position(portfolio, ticker)
    portfolio.positions.find_by(ticker: ticker.upcase)
  end

  # === Transactions ===

  def self.transactions(portfolio, limit: 100)
    portfolio.transactions.order(transaction_date: :desc).limit(limit)
  end

  def self.ticker_transactions(portfolio, ticker)
    portfolio.transactions.where(ticker: ticker.upcase).order(transaction_date: :desc)
  end

  def self.add_transaction(portfolio, ticker:, transaction_type:, quantity:, price_brl:,
                           fees_brl: 0.0, transaction_date: nil, notes: nil)
    transaction_date ||= Time.current
    total_brl = (quantity * price_brl) + fees_brl

    portfolio.transaction do
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
  end

  def self.delete_transaction(portfolio, transaction_id)
    txn = portfolio.transactions.find_by(id: transaction_id)
    return false unless txn

    ticker = txn.ticker
    txn.destroy!
    recalculate_position(portfolio, ticker)
    true
  end

  # === Position recalc ===

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
      raise ArgumentError, "Cannot sell more than the held quantity" if txn.quantity > pos.quantity

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

  def self.recalculate_position(portfolio, ticker)
    pos = find_position(portfolio, ticker)
    pos&.destroy!

    portfolio.transactions.where(ticker: ticker.upcase)
             .order(:transaction_date).each do |txn|
      update_position_from_transaction(portfolio, ticker, txn)
    end
  end

  # === Performance ===

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

    unrealized_pnl = total_current - total_invested
    transaction_metrics = transaction_performance(portfolio)
    realized_pnl = transaction_metrics[:realized_pnl]
    dividends = transaction_metrics[:dividends]
    total_pnl = unrealized_pnl + realized_pnl
    pnl_pct = transaction_metrics[:total_contributed].positive? ? (total_pnl / transaction_metrics[:total_contributed]) * 100 : 0

    {
      portfolio_id: portfolio.id,
      total_invested: total_invested.round(2),
      total_current_value: total_current.round(2),
      unrealized_profit_loss: unrealized_pnl.round(2),
      realized_profit_loss: realized_pnl.round(2),
      total_profit_loss: total_pnl.round(2),
      total_profit_loss_pct: pnl_pct.round(2),
      dividend_income: dividends.round(2),
      total_return: (total_pnl + dividends).round(2),
      total_return_pct: transaction_metrics[:total_contributed].positive? ? (((total_pnl + dividends) / transaction_metrics[:total_contributed]) * 100).round(2) : 0,
      total_contributed: transaction_metrics[:total_contributed].round(2),
      positions_count: pos_data.size,
      positions: pos_data
    }
  end

  def self.transaction_performance(portfolio)
    quantities = Hash.new(0.0)
    cost_basis = Hash.new(0.0)
    realized_pnl = 0.0
    dividends = 0.0
    total_contributed = 0.0

    portfolio.transactions.order(:transaction_date, :id).each do |txn|
      ticker = txn.ticker.upcase

      case txn.transaction_type
      when "buy"
        quantities[ticker] += txn.quantity
        cost_basis[ticker] += txn.total_brl
        total_contributed += txn.total_brl
      when "sell"
        average_cost = quantities[ticker].positive? ? cost_basis[ticker] / quantities[ticker] : 0.0
        realized_pnl += (txn.quantity * txn.price_brl) - txn.fees_brl - (average_cost * txn.quantity)
        quantities[ticker] -= txn.quantity
        cost_basis[ticker] -= average_cost * txn.quantity
      when "dividend"
        dividends += txn.total_brl - txn.fees_brl
      end
    end

    { realized_pnl: realized_pnl, dividends: dividends, total_contributed: total_contributed }
  end

  private_class_method :transaction_performance
end
