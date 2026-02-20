# frozen_string_literal: true
# typed: true

# Algorithmic watchlist scoring service.
# Ported from Python scoring.py.
module WatchlistScorer
  extend T::Sig

  sig { params(items: T::Array[T::Hash[Symbol, T.untyped]], min_score: Float, max_items: Integer).returns(T::Hash[Symbol, T::Array[T::Hash[Symbol, T.untyped]]]) }
  def self.build(items, min_score: 3.0, max_items: 12)
    candidates = []
    avoid_list = []

    items.each do |r|
      tipo = r[:tipo] || r["tipo"]
      next unless %w[stock us_stock].include?(tipo)

      score = 0.0
      reasons = []
      risk_flags = []

      rsi = r[:rsi_14] || r["rsi_14"]
      if rsi
        if rsi < 25
          score += 3.0
          reasons << "rsi_extreme_oversold"
        elsif rsi < 30
          score += 2.0
          reasons << "rsi_oversold"
        elsif rsi > 80
          score -= 3.0
          risk_flags << "rsi_extreme_overbought"
        elsif rsi > 70
          score -= 2.0
          risk_flags << "rsi_overbought"
        end
      end

      summary = r[:signal_summary] || r["signal_summary"]
      if summary == "bullish"
        score += 2.0
        reasons << "bullish_trend"
      elsif summary == "bearish"
        score -= 2.0
        risk_flags << "bearish_trend"
      end

      if (r[:signal_golden_cross] || r["signal_golden_cross"]) == 1
        score += 1.0
        reasons << "golden_cross"
      end

      if r[:above_ma_50] || r["above_ma_50"]
        score += 0.5
        reasons << "above_ma50"
      end

      if r[:above_ma_200] || r["above_ma_200"]
        score += 0.5
        reasons << "above_ma200"
      end

      if (r[:signal_52w_low] || r["signal_52w_low"]) == 1
        score += 1.0
        reasons << "near_52w_low"
      end

      if (r[:signal_52w_high] || r["signal_52w_high"]) == 1
        score -= 1.0
        risk_flags << "near_52w_high"
      end

      if (r[:signal_volume_spike] || r["signal_volume_spike"]) == 1
        score += 0.5
        reasons << "volume_spike"
      end

      news = r[:news_sentiment_combined] || r["news_sentiment_combined"]
      if news
        if news >= 0.4
          score += 2.0
          reasons << "news_positive_strong"
        elsif news >= 0.2
          score += 1.0
          reasons << "news_positive"
        elsif news <= -0.4
          score -= 2.0
          risk_flags << "news_negative_strong"
        elsif news <= -0.2
          score -= 1.0
          risk_flags << "news_negative"
        end
      end

      var_ytd = r[:var_ytd] || r["var_ytd"]
      if var_ytd
        if var_ytd >= 20
          score += 1.0
          reasons << "ytd_strong"
        elsif var_ytd <= -20
          score -= 1.0
          risk_flags << "ytd_weak"
        end
      end

      entry = {
        ticker: r[:ticker] || r["ticker"],
        nome: r[:nome] || r["nome"],
        score: score.round(2),
        rsi_14: rsi,
        var_ytd: var_ytd,
        news_sentiment: news,
        signal_summary: summary,
        reasons: reasons,
        risk_flags: risk_flags
      }

      if score >= min_score
        candidates << entry
      elsif score <= -2.0
        avoid_list << entry
      end
    end

    candidates.sort_by! { |x| [ -x[:score], x[:rsi_14] || 0 ] }
    avoid_list.sort_by! { |x| x[:score] }

    { watchlist: candidates.first(max_items), avoid_list: avoid_list.first(max_items) }
  end
end
