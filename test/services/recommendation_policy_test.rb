# frozen_string_literal: true

require "test_helper"

class RecommendationPolicyTest < ActiveSupport::TestCase
  test "disables recommendations and explains incomplete coverage" do
    health = {
      status: "warning",
      totals: {
        missing_current_date_assets: 5,
        stale_assets: 2,
        missing_price_assets: 0
      }
    }

    policy = RecommendationPolicy.evaluate(health: health)

    assert_not policy[:enabled]
    assert_equal "disabled", policy[:status]
    assert_includes policy[:reasons], "data health is warning"
    assert_includes policy[:reasons], "5 assets missing current-date data"
    assert_includes policy[:reasons], "2 stale assets"
  end

  test "enables recommendations only for healthy data" do
    health = { status: "healthy", totals: {} }

    policy = RecommendationPolicy.evaluate(health: health)

    assert policy[:enabled]
    assert_empty policy[:reasons]
  end
end
