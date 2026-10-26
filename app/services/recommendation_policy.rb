# frozen_string_literal: true

# Single safety boundary for algorithmic recommendations across reports, APIs,
# and the dashboard. A warning means the data may still be useful for
# observation, but not for an automated buy/avoid recommendation.
module RecommendationPolicy
  def self.evaluate(health: DataHealthChecker.report)
    enabled = health[:status] == "healthy"
    totals = health.fetch(:totals, {})
    reasons = []
    reasons << "data health is #{health[:status]}" unless enabled
    reasons << "#{totals[:missing_current_date_assets]} assets missing current-date data" if totals[:missing_current_date_assets].to_i.positive?
    reasons << "#{totals[:stale_assets]} stale assets" if totals[:stale_assets].to_i.positive?
    reasons << "#{totals[:missing_price_assets]} assets missing prices" if totals[:missing_price_assets].to_i.positive?

    {
      enabled: enabled,
      status: enabled ? "enabled" : "disabled",
      reasons: reasons,
      health: health
    }
  end

  def self.enabled?(health: DataHealthChecker.report)
    evaluate(health: health)[:enabled]
  end
end
