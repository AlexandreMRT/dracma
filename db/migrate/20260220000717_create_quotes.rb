class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quotes do |t|
      t.references :asset, null: false, foreign_key: true
      
      t.float :price_usd
      t.float :price_brl, null: false
      
      t.float :open_price
      t.float :high_price
      t.float :low_price
      t.float :volume
      
      # Variações percentuais históricas (BRL)
      t.float :change_1d
      t.float :change_1w
      t.float :change_1m
      t.float :change_ytd
      t.float :change_5y
      t.float :change_all
      
      # Preços históricos para referência
      t.float :price_1d_ago
      t.float :price_1w_ago
      t.float :price_1m_ago
      t.float :price_ytd
      t.float :price_5y_ago
      t.float :price_all_time
      
      # === FUNDAMENTAL DATA (for AI analysis) ===
      t.float :market_cap
      t.float :pe_ratio
      t.float :forward_pe
      t.float :pb_ratio
      t.float :dividend_yield
      t.float :eps
      
      # === RISK METRICS ===
      t.float :beta
      t.float :week_52_high
      t.float :week_52_low
      t.float :pct_from_52w_high
      
      # === TECHNICAL INDICATORS ===
      t.float :ma_50
      t.float :ma_200
      t.float :rsi_14
      t.integer :above_ma_50
      t.integer :above_ma_200
      t.integer :ma_50_above_200
      
      # === FINANCIAL HEALTH ===
      t.float :profit_margin
      t.float :roe
      t.float :debt_to_equity
      
      # === ANALYST DATA ===
      t.string :analyst_rating
      t.float :target_price
      t.integer :num_analysts
      
      # === BENCHMARK COMPARISON ===
      t.float :ibov_change_1d
      t.float :ibov_change_1w
      t.float :ibov_change_1m
      t.float :ibov_change_ytd
      t.float :sp500_change_1d
      t.float :sp500_change_1w
      t.float :sp500_change_1m
      t.float :sp500_change_ytd
      t.float :vs_ibov_1d
      t.float :vs_ibov_1m
      t.float :vs_ibov_ytd
      t.float :vs_sp500_1d
      t.float :vs_sp500_1m
      t.float :vs_sp500_ytd
      
      # === SECTOR CONTEXT ===
      t.float :sector_avg_pe
      t.float :sector_avg_change_1m
      t.float :sector_avg_change_ytd
      t.float :vs_sector_pe
      t.float :vs_sector_1m
      t.float :vs_sector_ytd
      
      # === TRADING SIGNALS ===
      t.integer :signal_golden_cross
      t.integer :signal_death_cross
      t.integer :signal_rsi_oversold
      t.integer :signal_rsi_overbought
      t.integer :signal_52w_high
      t.integer :signal_52w_low
      t.integer :signal_volume_spike
      t.string :signal_summary
      
      # === VOLATILITY ===
      t.float :volatility_30d
      t.float :avg_volume_20d
      t.float :volume_ratio
      
      # === NEWS SENTIMENT ===
      t.float :news_sentiment_pt
      t.float :news_sentiment_en
      t.float :news_sentiment_combined
      t.integer :news_count_pt
      t.integer :news_count_en
      t.string :news_headline_pt
      t.string :news_headline_en
      t.string :news_sentiment_label
      
      # === POLYMARKET PREDICTION MARKETS ===
      t.float :polymarket_score
      t.string :polymarket_label
      t.float :polymarket_confidence
      t.integer :polymarket_market_count
      t.float :polymarket_volume
      t.string :polymarket_top_question
      t.float :polymarket_top_probability
      
      t.datetime :quote_date, null: false
      t.datetime :fetched_at

      t.timestamps
    end
    add_index :quotes, [:asset_id, :quote_date], unique: true
  end
end
