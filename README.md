# Dracma

Brazilian stock market (B3) tracker and portfolio manager built with Ruby on Rails 8. Monitors 128 assets, detects trading signals, scores watchlists with algorithmic analysis, manages multi-user portfolios, and generates AI-ready reports — all with a modern Hotwire-powered UI.

Migrated from a Python/FastAPI application ([b3_tracker](../b3_tracker)).

## Current Status (2026-02-20)

- **128/128 assets** tracked and processed
- **101 Brazilian stocks** + 20 US stocks + 4 commodities + 2 crypto + 1 currency
- **10 trading signal types** with automatic bullish/bearish/neutral classification
- **Bilingual news sentiment** — Portuguese (60%) + English (40%) weighted scoring
- **Polymarket integration** — prediction market sentiment for crypto, macro, and geopolitics
- **Algorithmic watchlist** — composite scoring from RSI, trend, news, 52W proximity, and more
- **Multi-user** — Google OAuth 2.0 with session-based auth
- **Sorbet typed** — all 10 services annotated with `# typed: true`
- **Scheduled** — quotes fetched 3x/day on weekdays, reports generated daily at 18:30

## Features

### Market Data & Analysis
- **Real-time quotes** — Yahoo Finance integration for all asset types (chart v8 + quoteSummary v10 APIs)
- **Technical indicators** — RSI-14, MA50, MA200, 30-day volatility, volume ratio (vs 20-day avg)
- **Fundamental data** — P/E, Forward P/E, P/B, dividend yield, EPS, market cap, profit margin, ROE, debt/equity, beta
- **Benchmark comparison** — performance vs IBOV and S&P 500 (1D, 1W, 1M, YTD)
- **Dual currency** — all prices displayed in both BRL and USD

### Trading Signals
- **10 signal types** detected automatically from quote data
- **Bullish/bearish classification** — ≥3 bullish signals → bullish; ≥3 bearish → bearish; otherwise neutral
- Golden cross / death cross detection (MA50 vs MA200)
- RSI oversold (< 30) / overbought (> 70)
- Near 52-week high (within 5%) / near 52-week low (within 5%)
- Volume spike (> 2x 20-day average)
- Positive / negative news sentiment (threshold: ±0.3)

### News & Sentiment
- **Google News RSS** — bilingual feeds in Portuguese and English
- **Custom sentiment analyzer** — VADER-inspired with 26 Portuguese and 18 English financial keywords
- **Weighted scoring** — 60% PT + 40% EN for Brazilian stocks; 100% EN for US stocks
- **Soft normalization** — tanh-like function bounds scores to [-1, +1]

### Polymarket Integration
- **Prediction markets** — pulls data from Polymarket's Gamma API
- **Asset matching** — keyword-based matching to tracked assets (BTC, ETH, macro themes)
- **Volume-weighted sentiment** — aggregate sentiment with confidence scores
- **Included in AI reports** — crypto, macro, geopolitical, and sector sentiment categories

### Watchlist Scoring
- **Composite algorithm** combining multiple factors:
  - RSI: +3 (extreme oversold) to -3 (extreme overbought)
  - Signal summary: ±2 (bullish/bearish)
  - Golden cross: +1
  - MA position: ±0.5 each (above/below MA50, MA200)
  - 52-week proximity: ±1 (near low/high)
  - Volume spike: +0.5
  - News sentiment: ±1 to ±2
  - YTD performance: ±1 (contrarian)
- **Ranked output** — buy candidates and avoid list with scores and reasoning

### Portfolio Management
- **Multi-portfolio** — create, edit, delete portfolios per user
- **Transaction tracking** — buy, sell, dividend, split, merge
- **Automatic recalculation** — average price updated on buys, position reduced on sells
- **P&L performance** — per-position and portfolio-level profit/loss tracking
- **Position detail** — view position with all related transactions and performance metrics

### Exports & Reports
- **CSV** — all quotes with Portuguese field names (`preco_brl`, `setor`, `var_1d`)
- **JSON** — structured data with metadata and market summary
- **Markdown report** — human-readable market summary, top movers, signals, news, Polymarket
- **AI JSON report** — structured for AI consumption with actionable insights, algorithmic watchlist, and full data

### Web Interface
- **Dashboard** — market overview with gainers/losers, bullish/bearish signals, benchmarks, watchlist scoring
- **Instruments** — filterable asset catalog with sector and type filters
- **Quotes** — sortable daily quotes table
- **Watchlists** — add/remove tickers with notes
- **Portfolios** — full CRUD with nested positions and transactions
- **Exports** — download CSV, JSON, and generate reports from the UI

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Rails 8.1.2 (load_defaults 8.0) |
| Ruby | 3.3+ |
| Database | PostgreSQL 16 |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Asset Pipeline | Propshaft + Importmap |
| Background Jobs | Solid Queue (+ Solid Cache, Solid Cable) |
| Auth | OmniAuth (Google OAuth2) |
| Type Checking | Sorbet (`# typed: true` on all services) |
| Linting | RuboCop (Rails Omakase + rubocop-minitest) |
| Security | Brakeman |
| Testing | Minitest + WebMock + Capybara + Selenium |
| Deployment | Kamal (Docker), Thruster |

## Tracked Assets

### Brazilian Stocks (101 assets)

| Sector | Examples |
|--------|----------|
| Banking | BBAS3, ITUB4, BBDC4, SANB11, BPAC11 |
| Oil & Gas | PETR4, PRIO3, CSAN3, VBBR3 |
| Mining & Steel | VALE3, CSNA3, CMIN3, GGBR4 |
| Electric Utilities | ELET3, EGIE3, EQTL3, CPFE3 |
| Retail | MGLU3, LREN3, AMER3, BHIA3 |
| Healthcare | RDOR3, HAPV3, RADL3, FLRY3 |
| Industrial | WEGE3, EMBR3, SUZB3, KLBN11 |
| And more... | 101 total Ibovespa stocks |

### US Stocks (20 assets)

| Sector | Examples |
|--------|----------|
| Big Tech | AAPL, MSFT, GOOGL, AMZN, META, NVDA |
| Financial | JPM, BAC, WFC, GS |
| Healthcare | JNJ, UNH, PFE |
| Consumer | KO, PEP, MCD, WMT |
| Energy | XOM |
| Automotive | TSLA |

### Commodities, Crypto & Currency

| Type | Assets |
|------|--------|
| Commodities | Gold (GC=F), Silver (SI=F), Platinum (PL=F), Palladium (PA=F) |
| Crypto | Bitcoin (BTC-USD), Ethereum (ETH-USD) |
| Currency | USD/BRL (USDBRL=X) |

## Database Schema

| Table | Key Columns | Constraints |
|-------|-------------|-------------|
| **users** | `id` (UUID), `google_id`, `email`, `name`, `picture_url`, `default_currency`, `last_login` | Unique: `google_id`, `email` |
| **assets** | `id`, `ticker`, `name`, `sector`, `asset_type`, `unit` | Unique: `ticker` |
| **quotes** | `id`, `asset_id` (FK), `quote_date`, 60+ price/indicator/signal/news/polymarket columns | Unique: `(asset_id, quote_date)` |
| **portfolios** | `id`, `user_id` (FK→UUID), `name`, `is_default` | |
| **positions** | `id`, `portfolio_id` (FK), `ticker`, `quantity`, `avg_price_brl` | Unique: `(portfolio_id, ticker)` |
| **transactions** | `id`, `portfolio_id` (FK), `ticker`, `transaction_type` (enum: 1–5), `quantity`, `price_brl`, `total_brl`, `fees_brl`, `transaction_date` | |
| **watchlists** | `id`, `user_id` (FK→UUID), `ticker`, `notes` | Unique: `(user_id, ticker)` |

## Routes

### Authentication

| Method | Path | Description |
|--------|------|-------------|
| GET | `/login` | Login page |
| GET | `/auth/google_oauth2/callback` | OAuth callback |
| GET | `/auth/failure` | OAuth failure |
| DELETE | `/logout` | Logout |

### Web UI

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Dashboard — market overview, signals, watchlist scoring |
| GET | `/instruments` | Asset catalog (filterable by sector/type) |
| GET | `/instruments/:id` | Asset detail with 30 latest quotes |
| GET | `/quotes` | All quotes for a date (sortable) |
| GET | `/watchlists` | Watchlist management |
| POST | `/watchlists` | Add ticker to watchlist |
| DELETE | `/watchlists/:id` | Remove from watchlist |
| CRUD | `/portfolios` | Portfolio management |
| GET | `/portfolios/:id/positions` | Portfolio positions |
| GET | `/portfolios/:id/positions/:id` | Position detail with P&L + transactions |
| GET/POST/DELETE | `/portfolios/:id/transactions` | Transaction management |
| GET | `/exports` | List exported files |
| GET | `/exports/csv` | Download CSV |
| GET | `/exports/json` | Download JSON |
| GET | `/exports/report` | Generate Markdown + AI reports |

### JSON API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/quotes` | All quotes (filter: `?date=`) |
| GET | `/api/signals` | Trading signals (bullish, bearish, RSI, 52W, volume) |
| GET | `/api/scoring` | Algorithmic watchlist scoring |

All routes require login except `/login` and `/auth/*`.

## Signal Types

| Signal | Condition | Type |
|--------|-----------|------|
| `RSI_OVERSOLD` | RSI < 30 | Bullish |
| `RSI_OVERBOUGHT` | RSI > 70 | Bearish |
| `GOLDEN_CROSS` | MA50 crossed above MA200 | Bullish |
| `DEATH_CROSS` | MA50 crossed below MA200 | Bearish |
| `BULLISH_TREND` | Price above both MA50 and MA200 | Bullish |
| `BEARISH_TREND` | Price below both MA50 and MA200 | Bearish |
| `NEAR_52W_HIGH` | Within 5% of 52-week high | Bearish |
| `NEAR_52W_LOW` | Within 5% of 52-week low | Bullish |
| `VOLUME_SPIKE` | Volume > 2x 20-day average | Neutral |
| `POSITIVE_NEWS` | Sentiment score > 0.3 | Bullish |
| `NEGATIVE_NEWS` | Sentiment score < -0.3 | Bearish |

## Scheduled Jobs

Via Solid Queue recurring schedule (production only):

| Job | Schedule | Description |
|-----|----------|-------------|
| `FetchQuotesJob` | Weekdays at 10:00, 14:00, 18:00 | Fetch all quotes via `QuoteFetcher` |
| `GenerateReportsJob` | Weekdays at 18:30 | Generate CSV, JSON, MD, and AI reports |
| `clear_solid_queue_finished_jobs` | Every hour at :12 | Clean up finished Solid Queue jobs |

## Prerequisites

- Ruby 3.3+
- PostgreSQL 14+
- Node.js (for Tailwind CSS build)
- Google OAuth2 credentials (for authentication)

## Setup

```bash
# Clone and install
git clone <repo-url> dracma
cd dracma
bundle install

# Environment variables
export GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=your-client-secret
export SECRET_KEY_BASE=$(bin/rails secret)

# Database
bin/rails db:create db:migrate db:seed

# Run
bin/dev
```

The app will be available at `http://localhost:3000`.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_CLIENT_ID` | Yes | Google OAuth2 client ID |
| `GOOGLE_CLIENT_SECRET` | Yes | Google OAuth2 client secret |
| `SECRET_KEY_BASE` | Yes (prod) | Rails secret key for session encryption |
| `DATABASE_URL` | No | PostgreSQL connection URL (defaults to local) |
| `RAILS_ENV` | No | Environment (`development`, `test`, `production`) |

## Running Tests

```bash
# Full test suite
bin/rails test

# Specific test file
bin/rails test test/services/signal_detector_test.rb

# Specific test by name
bin/rails test test/services/signal_detector_test.rb -n test_rsi_oversold

# With verbose output
bin/rails test -v
```

## Code Quality

```bash
# RuboCop — check for offenses
bundle exec rubocop

# RuboCop — auto-fix correctable offenses
bundle exec rubocop -A

# Brakeman — security scan
bin/brakeman

# Sorbet — type checking
bundle exec srb tc
```

## Architecture

```
app/
├── controllers/           # Thin controllers, delegate to services
│   ├── api/               # JSON API (BaseController skips CSRF)
│   │   ├── base_controller.rb
│   │   ├── quotes_controller.rb
│   │   ├── scoring_controller.rb
│   │   └── signals_controller.rb
│   ├── application_controller.rb  # Global require_login
│   ├── dashboard_controller.rb
│   ├── portfolios_controller.rb
│   └── ...
├── javascript/
│   └── controllers/       # Stimulus controllers
│       ├── flash_controller.js      # Auto-dismiss flash messages
│       ├── auto_refresh_controller.js
│       ├── confirm_controller.js    # Action confirmation dialogs
│       └── sortable_controller.js   # Client-side table sorting
├── jobs/                  # Solid Queue background jobs
│   ├── fetch_quotes_job.rb
│   └── generate_reports_job.rb
├── models/                # ActiveRecord models (7 tables)
│   ├── user.rb            # UUID PK, from_omniauth
│   ├── asset.rb
│   ├── quote.rb           # 60+ columns
│   ├── portfolio.rb
│   ├── position.rb
│   ├── transaction.rb
│   └── watchlist.rb
├── services/              # Business logic (all Sorbet-typed)
│   ├── asset_catalog.rb          # 128 tracked assets (frozen hash catalog)
│   ├── exporter_service.rb       # CSV/JSON/MD/AI report generation
│   ├── news_fetcher.rb           # Google News RSS (PT + EN)
│   ├── polymarket_client.rb      # Prediction market sentiment
│   ├── portfolio_service.rb      # Portfolio CRUD & P&L calculation
│   ├── quote_fetcher.rb          # Orchestrator: fetch → detect → save
│   ├── sentiment_analyzer.rb     # VADER-inspired bilingual scoring
│   ├── signal_detector.rb        # 10 signal types, classification
│   ├── watchlist_scorer.rb       # Composite scoring algorithm
│   └── yahoo_finance_client.rb   # Yahoo Finance API with retry/backoff
└── views/                 # ERB templates with Tailwind CSS v4

config/
├── routes.rb              # RESTful routes + API namespace
├── recurring.yml          # Solid Queue cron schedule
└── initializers/
    └── omniauth.rb        # Google OAuth2 configuration
```

## Docker

```bash
# Development (with PostgreSQL)
docker compose up

# Rebuild after Gemfile changes
docker compose build
docker compose up

# Run migrations inside container
docker compose exec web bin/rails db:migrate

# Rails console inside container
docker compose exec web bin/rails console

# Production deployment (via Kamal)
kamal setup    # first deploy
kamal deploy   # subsequent deploys
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for detailed plans including:
- Parallel quote fetching (8-worker thread pool)
- Additional API endpoints (sectors, movers, news, refresh)
- Rake tasks for CLI operations
- CI/CD pipeline (GitHub Actions)
- Telegram bot alerts
- Weekly email reports
- Data quality monitoring
- Oracle Cloud deployment

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for coding conventions, testing guidelines, Sorbet/RuboCop rules, and the complete AI agent development guide.

## License

Private project.
