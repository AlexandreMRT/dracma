# frozen_string_literal: true

module DataHealthChecker
  DEFAULT_STALE_AFTER_HOURS = 8
  DEFAULT_OUTLIER_CHANGE_1D_PCT = 15.0
  MAX_SAMPLE_SIZE = 20

  def self.report(stale_after_hours: DEFAULT_STALE_AFTER_HOURS, outlier_change_1d_pct: DEFAULT_OUTLIER_CHANGE_1D_PCT)
    latest_quotes = latest_quotes_for_assets
    total_assets = Asset.count
    assets_with_quotes = latest_quotes.size

    stale_cutoff = stale_after_hours.to_f.hours.ago
    stale_quotes = latest_quotes.select { |quote| quote.fetched_at.nil? || quote.fetched_at < stale_cutoff }
    missing_price_quotes = latest_quotes.select { |quote| quote.price_brl.to_f <= 0.0 || quote.price_usd.nil? }
    missing_volume_quotes = latest_quotes.select { |quote| quote.volume.nil? || quote.volume.to_f <= 0 }
    outlier_quotes = latest_quotes.select do |quote|
      change = quote.change_1d
      !change.nil? && change.to_f.abs >= outlier_change_1d_pct.to_f
    end

    {
      status: status_for(
        total_assets: total_assets,
        assets_with_quotes: assets_with_quotes,
        stale_count: stale_quotes.size,
        missing_price_count: missing_price_quotes.size,
        missing_volume_count: missing_volume_quotes.size,
        outlier_count: outlier_quotes.size
      ),
      generated_at: Time.current.iso8601,
      latest_quote_date: latest_quotes.map(&:quote_date).compact.max&.strftime("%Y-%m-%d"),
      totals: {
        assets: total_assets,
        assets_with_quotes: assets_with_quotes,
        stale_assets: stale_quotes.size,
        missing_price_assets: missing_price_quotes.size,
        missing_volume_assets: missing_volume_quotes.size,
        outlier_change_1d_assets: outlier_quotes.size,
        coverage_percent: percent(assets_with_quotes, total_assets)
      },
      samples: {
        stale_tickers: sample_tickers(stale_quotes),
        missing_price_tickers: sample_tickers(missing_price_quotes),
        missing_volume_tickers: sample_tickers(missing_volume_quotes),
        outlier_change_1d_tickers: sample_tickers(outlier_quotes)
      }
    }
  end

  def self.latest_quotes_for_assets
    latest_per_asset = Quote.select("asset_id, MAX(quote_date) AS quote_date").group(:asset_id)

    Quote
      .joins("INNER JOIN (#{latest_per_asset.to_sql}) latest_quotes ON latest_quotes.asset_id = quotes.asset_id AND latest_quotes.quote_date = quotes.quote_date")
      .includes(:asset)
      .to_a
  end

  def self.status_for(total_assets:, assets_with_quotes:, stale_count:, missing_price_count:, missing_volume_count:, outlier_count:)
    return "warning" if total_assets.zero?
    return "critical" if total_assets.positive? && assets_with_quotes.zero?
    return "critical" if assets_with_quotes.positive? && stale_count >= (assets_with_quotes / 2.0).ceil

    if stale_count.positive? || missing_price_count.positive? || missing_volume_count.positive? || outlier_count.positive?
      "warning"
    else
      "healthy"
    end
  end

  def self.percent(numerator, denominator)
    return 0.0 if denominator.to_i <= 0

    ((numerator.to_f / denominator.to_f) * 100.0).round(1)
  end

  def self.sample_tickers(quotes)
    quotes.sort_by { |quote| quote.asset&.ticker.to_s }
          .first(MAX_SAMPLE_SIZE)
          .map { |quote| quote.asset&.ticker }
          .compact
  end

  private_class_method :latest_quotes_for_assets, :status_for, :percent, :sample_tickers
end
