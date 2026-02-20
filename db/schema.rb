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

ActiveRecord::Schema[8.0].define(version: 2026_02_20_000717) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "name", null: false
    t.string "sector", null: false
    t.string "asset_type", null: false
    t.string "unit", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticker"], name: "index_assets_on_ticker", unique: true
  end

  create_table "portfolios", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.string "ticker", null: false
    t.float "quantity", default: 0.0
    t.float "avg_price_brl", default: 0.0
    t.datetime "first_purchase_date"
    t.datetime "last_transaction_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "ticker"], name: "index_positions_on_portfolio_id_and_ticker", unique: true
    t.index ["portfolio_id"], name: "index_positions_on_portfolio_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.float "price_usd"
    t.float "price_brl", null: false
    t.float "open_price"
    t.float "high_price"
    t.float "low_price"
    t.float "volume"
    t.float "change_1d"
    t.float "change_1w"
    t.float "change_1m"
    t.float "change_ytd"
    t.float "change_5y"
    t.float "change_all"
    t.float "price_1d_ago"
    t.float "price_1w_ago"
    t.float "price_1m_ago"
    t.float "price_ytd"
    t.float "price_5y_ago"
    t.float "price_all_time"
    t.float "market_cap"
    t.float "pe_ratio"
    t.float "forward_pe"
    t.float "pb_ratio"
    t.float "dividend_yield"
    t.float "eps"
    t.float "beta"
    t.float "week_52_high"
    t.float "week_52_low"
    t.float "pct_from_52w_high"
    t.float "ma_50"
    t.float "ma_200"
    t.float "rsi_14"
    t.integer "above_ma_50"
    t.integer "above_ma_200"
    t.integer "ma_50_above_200"
    t.float "profit_margin"
    t.float "roe"
    t.float "debt_to_equity"
    t.string "analyst_rating"
    t.float "target_price"
    t.integer "num_analysts"
    t.float "ibov_change_1d"
    t.float "ibov_change_1w"
    t.float "ibov_change_1m"
    t.float "ibov_change_ytd"
    t.float "sp500_change_1d"
    t.float "sp500_change_1w"
    t.float "sp500_change_1m"
    t.float "sp500_change_ytd"
    t.float "vs_ibov_1d"
    t.float "vs_ibov_1m"
    t.float "vs_ibov_ytd"
    t.float "vs_sp500_1d"
    t.float "vs_sp500_1m"
    t.float "vs_sp500_ytd"
    t.float "sector_avg_pe"
    t.float "sector_avg_change_1m"
    t.float "sector_avg_change_ytd"
    t.float "vs_sector_pe"
    t.float "vs_sector_1m"
    t.float "vs_sector_ytd"
    t.integer "signal_golden_cross"
    t.integer "signal_death_cross"
    t.integer "signal_rsi_oversold"
    t.integer "signal_rsi_overbought"
    t.integer "signal_52w_high"
    t.integer "signal_52w_low"
    t.integer "signal_volume_spike"
    t.string "signal_summary"
    t.float "volatility_30d"
    t.float "avg_volume_20d"
    t.float "volume_ratio"
    t.float "news_sentiment_pt"
    t.float "news_sentiment_en"
    t.float "news_sentiment_combined"
    t.integer "news_count_pt"
    t.integer "news_count_en"
    t.string "news_headline_pt"
    t.string "news_headline_en"
    t.string "news_sentiment_label"
    t.float "polymarket_score"
    t.string "polymarket_label"
    t.float "polymarket_confidence"
    t.integer "polymarket_market_count"
    t.float "polymarket_volume"
    t.string "polymarket_top_question"
    t.float "polymarket_top_probability"
    t.datetime "quote_date", null: false
    t.datetime "fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "quote_date"], name: "index_quotes_on_asset_id_and_quote_date", unique: true
    t.index ["asset_id"], name: "index_quotes_on_asset_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.string "ticker", null: false
    t.integer "transaction_type", null: false
    t.float "quantity", null: false
    t.float "price_brl", null: false
    t.float "total_brl", null: false
    t.float "fees_brl", default: 0.0
    t.datetime "transaction_date", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id"], name: "index_transactions_on_portfolio_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "google_id", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "picture_url"
    t.string "default_currency", default: "BRL"
    t.datetime "last_login"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_id"], name: "index_users_on_google_id", unique: true
  end

  create_table "watchlists", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "ticker", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "ticker"], name: "index_watchlists_on_user_id_and_ticker", unique: true
    t.index ["user_id"], name: "index_watchlists_on_user_id"
  end

  add_foreign_key "portfolios", "users"
  add_foreign_key "positions", "portfolios"
  add_foreign_key "quotes", "assets"
  add_foreign_key "transactions", "portfolios"
  add_foreign_key "watchlists", "users"
end
