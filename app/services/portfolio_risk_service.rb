# frozen_string_literal: true

module PortfolioRiskService
  POSITION_CONCENTRATION_LIMIT = 30.0
  GROUP_CONCENTRATION_LIMIT = 40.0

  def self.analyze(portfolio, health: DataHealthChecker.report)
    rows = portfolio.positions.map { |position| position_row(position) }.compact
    total_value = rows.sum { |row| row[:current_value] }
    warnings = []

    rows.each do |row|
      percentage = percent(row[:current_value], total_value)
      next unless percentage >= POSITION_CONCENTRATION_LIMIT

      warnings << "#{row[:ticker]} is #{percentage}% of the portfolio"
    end

    [ [ :sector, "sector" ], [ :asset_type, "asset type" ] ].each do |key, label|
      grouped = rows.group_by { |row| row[key] }.transform_values { |items| items.sum { |row| row[:current_value] } }
      grouped.each do |group, value|
        percentage = percent(value, total_value)
        next unless percentage >= GROUP_CONCENTRATION_LIMIT

        warnings << "#{group} exposure is #{percentage}% of the portfolio"
      end
    end

    {
      status: warnings.empty? ? "balanced" : "concentrated",
      warnings: warnings,
      data_health: health,
      totals: {
        current_value: total_value.round(2),
        positions: rows.size,
        priced_positions: rows.count { |row| row[:current_price] }
      },
      by_sector: grouped_values(rows, :sector, total_value),
      by_asset_type: grouped_values(rows, :asset_type, total_value),
      positions: rows
    }
  end

  def self.position_row(position)
    asset = Asset.find_by(ticker: position.ticker)
    return nil unless asset

    quote = asset.quotes.order(quote_date: :desc).first
    current_price = quote&.price_brl
    current_value = current_price ? position.quantity * current_price : 0.0

    {
      ticker: position.ticker,
      sector: asset.sector,
      asset_type: asset.asset_type,
      quantity: position.quantity,
      avg_price_brl: position.avg_price_brl,
      current_price: current_price,
      current_value: current_value,
      quote_date: quote&.quote_date&.strftime("%Y-%m-%d"),
      stale: quote.nil? || quote.fetched_at.nil? || quote.fetched_at < DataHealthChecker::DEFAULT_STALE_AFTER_HOURS.hours.ago
    }
  end

  def self.grouped_values(rows, key, total_value)
    rows.group_by { |row| row[key] }.map do |group, items|
      value = items.sum { |row| row[:current_value] }
      { name: group, current_value: value.round(2), percentage: percent(value, total_value) }
    end.sort_by { |row| -row[:current_value] }
  end

  def self.percent(value, total)
    return 0.0 unless total.to_f.positive?

    ((value.to_f / total.to_f) * 100).round(1)
  end

  private_class_method :position_row, :grouped_values, :percent
end
