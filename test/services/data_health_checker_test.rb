# frozen_string_literal: true

require "test_helper"

class DataHealthCheckerTest < ActiveSupport::TestCase
  test "report summarizes stale missing and outlier metrics" do
    baseline = DataHealthChecker.report(stale_after_hours: 100_000, outlier_change_1d_pct: 99.0)

    fresh_asset = Asset.create!(ticker: "FRESH", name: "Fresh Asset", sector: "test", asset_type: "stock", unit: "")
    stale_asset = Asset.create!(ticker: "STALE", name: "Stale Asset", sector: "test", asset_type: "stock", unit: "")

    Quote.create!(
      asset: fresh_asset,
      quote_date: Time.current,
      price_brl: 10.0,
      price_usd: 2.0,
      volume: 1000,
      change_1d: 1.2,
      fetched_at: 1.hour.ago
    )

    Quote.create!(
      asset: stale_asset,
      quote_date: Time.current,
      price_brl: 20.0,
      price_usd: 4.0,
      volume: nil,
      change_1d: 18.0,
      fetched_at: nil
    )

    report = DataHealthChecker.report(stale_after_hours: 6, outlier_change_1d_pct: 15.0)

    assert_includes %w[warning critical], report[:status]
    assert_equal baseline.dig(:totals, :assets) + 2, report.dig(:totals, :assets)
    assert_equal baseline.dig(:totals, :assets_with_quotes) + 2, report.dig(:totals, :assets_with_quotes)
    assert_operator report.dig(:totals, :stale_assets), :>=, baseline.dig(:totals, :stale_assets) + 1
    assert_operator report.dig(:totals, :missing_volume_assets), :>=, baseline.dig(:totals, :missing_volume_assets) + 1
    assert_operator report.dig(:totals, :outlier_change_1d_assets), :>=, baseline.dig(:totals, :outlier_change_1d_assets) + 1
    assert report.dig(:totals).key?(:coverage_percent)
    assert_includes report.dig(:samples, :stale_tickers), "STALE"
    assert_includes report.dig(:samples, :missing_volume_tickers), "STALE"
    assert_includes report.dig(:samples, :outlier_change_1d_tickers), "STALE"
  end

  test "report is critical when quotes are stale" do
    report = DataHealthChecker.report(stale_after_hours: 0)

    assert_equal "critical", report[:status]
    assert_operator report.dig(:totals, :assets_with_quotes), :>=, 1
    assert_operator report.dig(:totals, :stale_assets), :>=, 1
  end

  test "report is warning when outliers exist without other issues" do
    outlier_asset = Asset.create!(ticker: "OUTLIER", name: "Outlier Asset", sector: "test", asset_type: "stock", unit: "")

    Quote.create!(
      asset: outlier_asset,
      quote_date: Time.current,
      price_brl: 50.0,
      price_usd: 10.0,
      volume: 1_000,
      change_1d: 25.0,
      fetched_at: Time.current
    )

    report = DataHealthChecker.report(stale_after_hours: 100_000, outlier_change_1d_pct: 15.0)

    assert_equal "warning", report[:status]
    assert_operator report.dig(:totals, :outlier_change_1d_assets), :>=, 1
  end

  test "report is warning when no assets exist" do
    Quote.delete_all
    Asset.delete_all

    report = DataHealthChecker.report

    assert_equal "warning", report[:status]
    assert_equal 0, report.dig(:totals, :assets)
    assert_equal 0, report.dig(:totals, :assets_with_quotes)
    assert_equal 0.0, report.dig(:totals, :coverage_percent)
  end
end
