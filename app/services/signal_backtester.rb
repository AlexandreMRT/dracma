# frozen_string_literal: true

# Leakage-safe event study for historical signals. It only evaluates returns
# after a signal is observed; it never uses future data to create the signal.
module SignalBacktester
  DEFAULT_HORIZONS = [ 1, 5, 20 ].freeze

  def self.run(rows, signal_key:, horizons: DEFAULT_HORIZONS)
    ordered = rows.sort_by { |row| value_for(row, :quote_date).to_s }
    observations = {}

    horizons.each do |horizon|
      events = []

      ordered.each_with_index do |row, index|
        next unless flag?(value_for(row, signal_key))

        future = ordered[index + horizon]
        current_price = value_for(row, :price_brl)
        future_price = future && value_for(future, :price_brl)
        next unless current_price.to_f.positive? && future_price.to_f.positive?

        events << ((future_price.to_f / current_price.to_f - 1.0) * 100.0)
      end

      observations["#{horizon}d"] = summarize(events)
    end

    {
      signal: signal_key.to_s,
      source_rows: ordered.size,
      signal_events: ordered.count { |row| flag?(value_for(row, signal_key)) },
      horizons: observations
    }
  end

  def self.summarize(events)
    return { observations: 0, average_return_pct: nil, hit_rate_pct: nil } if events.empty?

    {
      observations: events.size,
      average_return_pct: (events.sum / events.size).round(2),
      hit_rate_pct: (events.count(&:positive?).to_f / events.size * 100.0).round(1)
    }
  end

  def self.value_for(row, key)
    row.respond_to?(:[]) ? (row[key] || row[key.to_s]) : row.public_send(key)
  end

  def self.flag?(value)
    value == true || value == 1
  end

  private_class_method :summarize, :value_for, :flag?
end
