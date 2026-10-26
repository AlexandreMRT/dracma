# frozen_string_literal: true

require "test_helper"

class ExporterDashboardSnapshotTest < ActiveSupport::TestCase
  test "does not expose watchlist recommendations when data is unhealthy" do
    snapshot = ExporterService.send(:build_dashboard_snapshot, [
      {
        tipo: "stock",
        ticker: "TEST",
        var_1d: 1.0,
        signal_summary: "bullish",
        setor: "test"
      }
    ])

    assert_equal "critical", snapshot.dig(:data_health, :status)
    assert_not snapshot.dig(:recommendation_policy, :enabled)
    assert_empty snapshot.dig(:watchlist_data, :watchlist)
  end
end
