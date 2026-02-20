# frozen_string_literal: true

# Detects trading signals from quote data.
# Ported from Python signals.py - single source of truth for signal detection.
module SignalDetector
  RSI_OVERSOLD = 30
  RSI_OVERBOUGHT = 70
  VOLUME_SPIKE_RATIO = 2.0
  NEAR_52W_HIGH_PCT = -5
  NEAR_52W_LOW_PCT = 5
  NEWS_SENTIMENT_POS = 0.3
  NEWS_SENTIMENT_NEG = -0.3
  BULLISH_MIN_COUNT = 3
  BEARISH_MIN_COUNT = 3

  Result = Struct.new(
    :rsi_oversold, :rsi_overbought,
    :near_52w_high, :near_52w_low,
    :volume_spike, :golden_cross, :death_cross,
    :bullish_trend, :bearish_trend,
    :positive_news, :negative_news,
    :summary,
    keyword_init: true
  ) do
    def as_db_flags
      {
        signal_rsi_oversold: rsi_oversold ? 1 : 0,
        signal_rsi_overbought: rsi_overbought ? 1 : 0,
        signal_52w_high: near_52w_high ? 1 : 0,
        signal_52w_low: near_52w_low ? 1 : 0,
        signal_volume_spike: volume_spike ? 1 : 0,
        signal_golden_cross: golden_cross ? 1 : 0,
        signal_death_cross: death_cross ? 1 : 0,
        signal_summary: summary,
      }
    end

    def as_labels
      labels = []
      labels << "RSI_OVERSOLD" if rsi_oversold
      labels << "RSI_OVERBOUGHT" if rsi_overbought
      labels << "GOLDEN_CROSS" if golden_cross
      labels << "BULLISH_TREND" if bullish_trend
      labels << "BEARISH_TREND" if bearish_trend
      labels << "NEAR_52W_HIGH" if near_52w_high
      labels << "NEAR_52W_LOW" if near_52w_low
      labels << "VOLUME_SPIKE" if volume_spike
      labels << "POSITIVE_NEWS" if positive_news
      labels << "NEGATIVE_NEWS" if negative_news
      labels
    end
  end

  # Detect signals from a Hash or ActiveRecord object.
  def self.detect(data)
    g = ->(key) { data.is_a?(Hash) ? data[key] : data.try(key) }

    rsi = g.call(:rsi_14)
    rsi_oversold = rsi && rsi < RSI_OVERSOLD
    rsi_overbought = rsi && rsi > RSI_OVERBOUGHT

    pct_from_high = g.call(:pct_from_52w_high)
    near_52w_high = pct_from_high && pct_from_high >= NEAR_52W_HIGH_PCT

    week_52_low = g.call(:week_52_low)
    close = g.call(:close) || g.call(:price_brl)
    near_52w_low = if week_52_low && close && week_52_low > 0
                     ((close - week_52_low) / week_52_low) * 100 <= NEAR_52W_LOW_PCT
                   end

    volume_ratio = g.call(:volume_ratio)
    volume_spike = volume_ratio && volume_ratio >= VOLUME_SPIKE_RATIO

    ma_50_above_200 = g.call(:ma_50_above_200)
    golden_cross = ma_50_above_200 == 1
    death_cross = ma_50_above_200 == 0

    above_50 = g.call(:above_ma_50)
    above_200 = g.call(:above_ma_200)
    bullish_trend = above_50 == 1 && above_200 == 1
    bearish_trend = above_50 == 0 && above_200 == 0

    news = g.call(:news_sentiment_combined)
    positive_news = news && news > NEWS_SENTIMENT_POS
    negative_news = news && news < NEWS_SENTIMENT_NEG

    bullish_count = [rsi_oversold, near_52w_low, golden_cross, above_50 == 1, above_200 == 1].count(true)
    bearish_count = [rsi_overbought, near_52w_high, death_cross, above_50 == 0, above_200 == 0].count(true)

    summary = if bullish_count >= BULLISH_MIN_COUNT && bullish_count > bearish_count
                "bullish"
              elsif bearish_count >= BEARISH_MIN_COUNT && bearish_count > bullish_count
                "bearish"
              else
                "neutral"
              end

    Result.new(
      rsi_oversold: !!rsi_oversold,
      rsi_overbought: !!rsi_overbought,
      near_52w_high: !!near_52w_high,
      near_52w_low: !!near_52w_low,
      volume_spike: !!volume_spike,
      golden_cross: golden_cross,
      death_cross: death_cross,
      bullish_trend: bullish_trend,
      bearish_trend: bearish_trend,
      positive_news: !!positive_news,
      negative_news: !!negative_news,
      summary: summary,
    )
  end
end
