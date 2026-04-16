# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_16_003117) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "asset_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "sector", null: false
    t.string "ticker", null: false
    t.string "unit", default: ""
    t.datetime "updated_at", null: false
    t.index ["ticker"], name: "index_assets_on_ticker", unique: true
  end

  create_table "portfolios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_default", default: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.float "avg_price_brl", default: 0.0
    t.string "broker", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "first_purchase_date"
    t.datetime "last_transaction_date"
    t.text "notes"
    t.bigint "portfolio_id", null: false
    t.float "quantity", default: 0.0
    t.string "ticker", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "ticker", "broker"], name: "index_positions_on_portfolio_ticker_broker", unique: true
    t.index ["portfolio_id"], name: "index_positions_on_portfolio_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.integer "above_ma_200"
    t.integer "above_ma_50"
    t.string "analyst_rating"
    t.bigint "asset_id", null: false
    t.float "avg_volume_20d"
    t.float "beta"
    t.float "change_1d"
    t.float "change_1m"
    t.float "change_1w"
    t.float "change_5y"
    t.float "change_all"
    t.float "change_ytd"
    t.datetime "created_at", null: false
    t.float "debt_to_equity"
    t.float "dividend_yield"
    t.float "eps"
    t.datetime "fetched_at"
    t.float "forward_pe"
    t.float "high_price"
    t.float "ibov_change_1d"
    t.float "ibov_change_1m"
    t.float "ibov_change_1w"
    t.float "ibov_change_ytd"
    t.float "low_price"
    t.float "ma_200"
    t.float "ma_50"
    t.integer "ma_50_above_200"
    t.float "market_cap"
    t.integer "news_count_en"
    t.integer "news_count_pt"
    t.string "news_headline_en"
    t.string "news_headline_pt"
    t.float "news_sentiment_combined"
    t.float "news_sentiment_en"
    t.string "news_sentiment_label"
    t.float "news_sentiment_pt"
    t.integer "num_analysts"
    t.float "open_price"
    t.float "pb_ratio"
    t.float "pct_from_52w_high"
    t.float "pe_ratio"
    t.float "polymarket_confidence"
    t.string "polymarket_label"
    t.integer "polymarket_market_count"
    t.float "polymarket_score"
    t.float "polymarket_top_probability"
    t.string "polymarket_top_question"
    t.float "polymarket_volume"
    t.float "price_1d_ago"
    t.float "price_1m_ago"
    t.float "price_1w_ago"
    t.float "price_5y_ago"
    t.float "price_all_time"
    t.float "price_brl", null: false
    t.float "price_usd"
    t.float "price_ytd"
    t.float "profit_margin"
    t.datetime "quote_date", null: false
    t.float "roe"
    t.float "rsi_14"
    t.float "sector_avg_change_1m"
    t.float "sector_avg_change_ytd"
    t.float "sector_avg_pe"
    t.integer "signal_52w_high"
    t.integer "signal_52w_low"
    t.integer "signal_death_cross"
    t.integer "signal_golden_cross"
    t.integer "signal_rsi_overbought"
    t.integer "signal_rsi_oversold"
    t.string "signal_summary"
    t.integer "signal_volume_spike"
    t.float "sp500_change_1d"
    t.float "sp500_change_1m"
    t.float "sp500_change_1w"
    t.float "sp500_change_ytd"
    t.float "target_price"
    t.datetime "updated_at", null: false
    t.float "volatility_30d"
    t.float "volume"
    t.float "volume_ratio"
    t.float "vs_ibov_1d"
    t.float "vs_ibov_1m"
    t.float "vs_ibov_ytd"
    t.float "vs_sector_1m"
    t.float "vs_sector_pe"
    t.float "vs_sector_ytd"
    t.float "vs_sp500_1d"
    t.float "vs_sp500_1m"
    t.float "vs_sp500_ytd"
    t.float "week_52_high"
    t.float "week_52_low"
    t.index ["asset_id", "quote_date"], name: "index_quotes_on_asset_id_and_quote_date", unique: true
    t.index ["asset_id"], name: "index_quotes_on_asset_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "broker", default: "", null: false
    t.datetime "created_at", null: false
    t.float "fees_brl", default: 0.0
    t.text "notes"
    t.bigint "portfolio_id", null: false
    t.float "price_brl", null: false
    t.float "quantity", null: false
    t.string "ticker", null: false
    t.float "total_brl", null: false
    t.datetime "transaction_date", null: false
    t.integer "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id"], name: "index_transactions_on_portfolio_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_currency", default: "BRL"
    t.string "email", null: false
    t.string "google_id", null: false
    t.datetime "last_login"
    t.string "name", null: false
    t.string "picture_url"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_id"], name: "index_users_on_google_id", unique: true
  end

  create_table "watchlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "ticker", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "ticker"], name: "index_watchlists_on_user_id_and_ticker", unique: true
    t.index ["user_id"], name: "index_watchlists_on_user_id"
  end

  add_foreign_key "portfolios", "users"
  add_foreign_key "positions", "portfolios"
  add_foreign_key "quotes", "assets"
  add_foreign_key "transactions", "portfolios"
  add_foreign_key "watchlists", "users"
end
