# Dracma — Roadmap & Future Plans

> This file is structured for AI consumption. Use it to continue development in future sessions.

## Current State (v1.0 — 2026-02-20)

### Implemented Features

- [x] 128 assets tracked (101 BR stocks, 20 US stocks, 4 commodities, 2 crypto, 1 currency)
- [x] Yahoo Finance quote fetching (chart v8 + quoteSummary v10 APIs)
- [x] Exponential backoff with jitter, rate limiting, retry on 429/5xx
- [x] Technical indicators: RSI-14, MA50, MA200, golden/death cross, 30-day volatility, volume ratio
- [x] Fundamental data: P/E, Forward P/E, P/B, dividend yield, EPS, market cap, profit margin, ROE, debt/equity, beta
- [x] Trading signals: 10 types (RSI oversold/overbought, golden/death cross, bullish/bearish trend, near 52W high/low, volume spike, positive/negative news)
- [x] Signal classification: bullish/bearish/neutral (≥3 count threshold)
- [x] Bilingual news sentiment: Google News RSS in Portuguese (60% weight) + English (40% weight)
- [x] Custom VADER-inspired sentiment analyzer with Portuguese financial lexicon (26 PT + 18 EN keywords)
- [x] Polymarket prediction market integration (crypto, macro, geopolitical sentiment)
- [x] Algorithmic watchlist scoring (RSI + trend + golden cross + MA position + 52W proximity + volume + news + YTD)
- [x] Benchmark comparison: vs IBOV and S&P 500 (1D, 1W, 1M, YTD)
- [x] Dual currency: all prices in BRL and USD
- [x] **Web frontend dashboard** — Hotwire (Turbo + Stimulus) + Tailwind CSS v4
- [x] Dashboard with market overview, gainers/losers, signals, benchmarks, watchlist scoring
- [x] Asset catalog (filterable instruments page)
- [x] Sortable quotes table
- [x] Watchlist management UI (add/remove tickers, notes)
- [x] Portfolio management — full CRUD for portfolios, positions, transactions
- [x] Transaction types: buy, sell, dividend, split, merge
- [x] Automatic position recalculation (average price on buys, reduction on sells)
- [x] P&L performance tracking (per position and portfolio total)
- [x] Export: CSV, JSON, Markdown report, AI-structured JSON report
- [x] Polymarket data included in AI reports
- [x] Multi-user Google OAuth 2.0 authentication (OmniAuth)
- [x] Session-based auth with `require_login` globally enforced
- [x] PostgreSQL database with 7 tables (users with UUID PKs)
- [x] Scheduled jobs via Solid Queue (fetch quotes 3x/day weekdays, generate reports at 18:30)
- [x] Docker support with multi-stage build (Dockerfile + docker-compose.yml)
- [x] Production deployment via Kamal
- [x] **Sorbet type checking** — all 10 services annotated with `# typed: true` and `extend T::Sig`
- [x] **RuboCop** — Rails Omakase + rubocop-minitest
- [x] **Brakeman** — static security analysis
- [x] **Test suite** — Minitest + WebMock + fixtures, parallel execution
- [x] Stimulus controllers: flash (auto-dismiss), auto_refresh, confirm, sortable
- [x] JSON API namespace: `/api/quotes`, `/api/signals`, `/api/scoring`

### Tech Stack

- Ruby 3.3+ / Rails 8.1.2
- PostgreSQL 16 (+ Solid Cache, Solid Queue, Solid Cable)
- Hotwire (Turbo + Stimulus) + Tailwind CSS v4
- Propshaft + Importmap (no webpack/esbuild)
- Sorbet for type checking, RuboCop for linting, Brakeman for security
- Minitest + WebMock + Capybara for testing
- Kamal + Docker for deployment

---

## Priority Features (Next Up)

### 1. Parallel Quote Fetching ⚡
**Priority: HIGH | Effort: MEDIUM**

The Python b3_tracker fetches all 128 assets in ~30s using ThreadPoolExecutor with 8 workers. Dracma currently fetches sequentially, which is significantly slower.

**Implementation notes:**
- Use Ruby's `Concurrent::ThreadPoolExecutor` from the `concurrent-ruby` gem (already a Rails dependency)
- Or use the `parallel` gem for simpler API
- Fetch benchmarks first (3 concurrent), then assets (8 workers), then news (5 workers)
- Maintain rate limiting and backoff per-thread
- Target: ~30-45s for all 128 assets (vs ~4min sequential)

**Files to modify:**
- `app/services/quote_fetcher.rb` (refactor `fetch_all` to use thread pool)
- `app/services/yahoo_finance_client.rb` (ensure thread-safety)
- `Gemfile` (add `parallel` gem if chosen over `concurrent-ruby`)

---

### 2. Additional API Endpoints 🌐
**Priority: HIGH | Effort: MEDIUM**

The Python b3_tracker exposes 36+ API endpoints. Dracma has 3 API endpoints. Add the missing ones:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/quotes/:ticker` | GET | Detailed single asset data + signals + history |
| `/api/sectors` | GET | Sector performance aggregation |
| `/api/movers` | GET | Top gainers/losers (filter: `?period=&limit=`) |
| `/api/news` | GET | News sentiment data (filter: `?sentiment=`) |
| `/api/report` | GET | Full AI-ready consolidated report |
| `/api/refresh` | POST | Trigger background data refresh |
| `/api/watchlist` | GET/POST/DELETE | Watchlist CRUD (JSON) |
| `/api/portfolios` | CRUD | Portfolio management (JSON) |
| `/api/portfolios/:id/positions` | GET | Positions with P&L |
| `/api/portfolios/:id/performance` | GET | Portfolio performance metrics |
| `/api/portfolios/:id/transactions` | GET/POST/DELETE | Transaction management (JSON) |

**Files to create/modify:**
- `app/controllers/api/quotes_controller.rb` (add `show` action)
- `app/controllers/api/sectors_controller.rb` (new)
- `app/controllers/api/movers_controller.rb` (new)
- `app/controllers/api/news_controller.rb` (new)
- `app/controllers/api/report_controller.rb` (new)
- `app/controllers/api/refresh_controller.rb` (new)
- `app/controllers/api/watchlists_controller.rb` (new)
- `app/controllers/api/portfolios_controller.rb` (new)
- `config/routes.rb` (add new API routes)

---

### 3. Rake Tasks (CLI Equivalents) 🔧
**Priority: MEDIUM | Effort: LOW**

The Python b3_tracker has 9 CLI modes (`--once`, `--signals`, `--news`, etc.). Add equivalent Rake tasks:

| Task | Description |
|------|-------------|
| `rails quotes:fetch` | Fetch all quotes once |
| `rails quotes:signals` | Display active trading signals |
| `rails quotes:news` | Display news sentiment analysis |
| `rails quotes:polymarket` | Display Polymarket sentiment |
| `rails quotes:summary` | Display market summary |
| `rails export:csv` | Export quotes to CSV |
| `rails export:json` | Export quotes to JSON |
| `rails export:report` | Generate Markdown + AI reports |

**Files to create:**
- `lib/tasks/quotes.rake`
- `lib/tasks/export.rake`

---

### 4. API Documentation (Swagger/OpenAPI) 📖
**Priority: MEDIUM | Effort: MEDIUM**

Add auto-generated API documentation.

**Implementation notes:**
- Use `rswag` gem (integrates with RSpec) or `apipie-rails` (works with Minitest)
- Alternative: hand-crafted OpenAPI YAML + Swagger UI served as static asset
- Document all API endpoints with request/response schemas

**Files to create/modify:**
- `Gemfile` (add documentation gem)
- API controller annotations
- `config/routes.rb` (mount Swagger UI)

---

### 5. CI/CD Pipeline 🔄
**Priority: HIGH | Effort: LOW**

Automate testing, linting, and security checks on every push.

**GitHub Actions workflow:**
```yaml
# .github/workflows/ci.yml
jobs:
  test:
    - bin/rails test
    - bundle exec rubocop
    - bin/brakeman --no-pager
    - bundle exec srb tc
```

**Files to create:**
- `.github/workflows/ci.yml`

---

### 6. Increase Test Coverage 🧪
**Priority: HIGH | Effort: MEDIUM**

Current test suite covers models, some services, and controllers. Target: 80%+ coverage.

**Missing test coverage:**
- [ ] `QuoteFetcher` service (HTTP mocking with WebMock)
- [ ] `NewsFetcher` service (RSS feed mocking)
- [ ] `PolymarketClient` service (API mocking)
- [ ] `YahooFinanceClient` service (rate limiting, retries, error handling)
- [ ] `ExporterService` (CSV/JSON/report generation)
- [ ] Integration tests for dashboard with data
- [ ] System tests with Capybara (login flow, portfolio CRUD, watchlist management)

**Files to create:**
- `test/services/quote_fetcher_test.rb` (expand)
- `test/services/news_fetcher_test.rb` (new)
- `test/services/polymarket_client_test.rb` (new)
- `test/services/yahoo_finance_client_test.rb` (new)
- `test/services/exporter_service_test.rb` (new)
- `test/system/` (system tests)

**Tools:**
- Add `simplecov` gem for coverage reporting
- Add coverage threshold enforcement

---

### 7. Telegram Bot 🔔
**Priority: MEDIUM | Effort: MEDIUM**

Notify users when important events happen:
- RSI < 30 (oversold) or > 70 (overbought) on watched assets
- Golden/death cross detected
- Volume spike > 2x average
- Price near 52-week high/low
- Negative/positive news sentiment spike

**Implementation notes:**
- Use `telegram-bot-ruby` gem
- Create `app/services/telegram_notifier.rb`
- Create `app/jobs/send_alerts_job.rb`
- Store `TELEGRAM_BOT_TOKEN` and per-user `telegram_chat_id` in users table
- Commands: `/status`, `/watchlist`, `/add TICKER`, `/remove TICKER`, `/signals`

**Files to create/modify:**
- `app/services/telegram_notifier.rb` (new)
- `app/services/alert_detector.rb` (new — threshold-based alert logic)
- `app/jobs/send_alerts_job.rb` (new)
- `db/migrate/xxx_add_telegram_to_users.rb` (add `telegram_chat_id` column)
- `config/recurring.yml` (add alert check schedule)
- `Gemfile` (add `telegram-bot-ruby`)

---

### 8. Data Quality & Health Monitor ✅
**Priority: MEDIUM | Effort: MEDIUM**

Ensure data reliability before downstream analysis:
- Detect stale quotes (last update older than N hours)
- Missing/NaN fields per asset and per source
- Outlier detection on price/volume changes
- Market session anomalies (e.g., extreme spikes)
- Daily health report + alerts

**Implementation notes:**
- Create `app/services/data_health_checker.rb` with validation rules
- Add `/api/health/data` endpoint
- Include health summary in generated reports
- Add Solid Queue job for periodic health checks

**Files to create/modify:**
- `app/services/data_health_checker.rb` (new)
- `app/controllers/api/health_controller.rb` (new)
- `app/jobs/health_check_job.rb` (new)
- `app/services/exporter_service.rb` (include health summary)
- `config/recurring.yml` (add health check schedule)

---

### 9. Weekly Email Report 📧
**Priority: MEDIUM | Effort: LOW**

Send summary email every Friday after market close:
- Week's top gainers/losers
- New signals detected
- News sentiment summary
- Portfolio performance

**Implementation notes:**
- Use Action Mailer (built into Rails)
- Create `app/mailers/weekly_report_mailer.rb`
- Create HTML email template in `app/views/weekly_report_mailer/`
- Add Solid Queue recurring job: Fridays at 18:30
- Support configurable recipient per user (email from OAuth)

**Files to create/modify:**
- `app/mailers/weekly_report_mailer.rb` (new)
- `app/views/weekly_report_mailer/weekly_summary.html.erb` (new)
- `app/jobs/weekly_email_job.rb` (new)
- `config/recurring.yml` (add Friday schedule)

---

### 10. Deploy to Oracle Cloud Free Tier ☁️
**Priority: HIGH | Effort: LOW**

Free forever VM with 4 OCPUs, 24GB RAM (ARM Ampere):
- Always-on scheduled jobs
- App accessible from anywhere
- Telegram bot running 24/7

**Implementation notes:**
- Kamal is already configured (`config/deploy.yml`)
- Setup Caddy or nginx for HTTPS reverse proxy
- Use Cloudflare for DNS/protection
- Backup PostgreSQL with `pg_dump` to object storage

**Files to create:**
- `deploy/setup.sh` (server setup script)
- `deploy/Caddyfile` (reverse proxy)
- `deploy/README.md` (deployment guide)

---

## Future Features (Backlog)

### Static HTML Dashboard 📈
**Priority: LOW | Effort: MEDIUM**

Generate a self-contained HTML file daily with interactive charts:
- Chart.js or Plotly for visualizations
- Sector heatmap, top movers cards, signal summary
- No server needed — just open the HTML file
- Save to `exports/dashboard_YYYY-MM-DD.html`

### Backtesting Engine 🧪
**Priority: LOW | Effort: HIGH**

Test signal effectiveness historically:
- Requires historical data accumulation (run for 6+ months first)
- Calculate win rate of each signal type
- Sharpe ratio if followed signals
- Compare vs buy-and-hold benchmarks

### Graham Valuation Multiples 📐
**Priority: LOW | Effort: LOW**

Add Benjamin Graham valuation:
- Graham Number: √(22.5 × EPS × Book Value)
- Graham Multiple: P/E × P/B < 22.5
- Margin of Safety calculation

**Files to modify:**
- `app/services/quote_fetcher.rb` (add calculations)
- `db/migrate/xxx_add_graham_fields.rb` (add columns)

### Sector Correlation Matrix 🔗
**Priority: LOW | Effort: MEDIUM**

Identify correlated assets:
- Calculate 30-day rolling correlation between sectors
- Heatmap visualization
- Alert on unusual correlation breaks

### Insider Trading Alerts 👔
**Priority: LOW | Effort: HIGH**

Monitor CVM filings for insider transactions:
- Scrape CVM website or use their API
- Alert on significant insider buys/sells
- Store in database for historical analysis

### Portfolio Comparison vs Benchmarks 📊
**Priority: LOW | Effort: MEDIUM**

Compare portfolio performance against IBOV and S&P 500:
- Time-weighted return calculation
- Sharpe ratio, max drawdown
- Alpha and beta calculation
- Requires historical position snapshots

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Dracma (Rails 8)                   │
├────────────────┬────────────────┬────────────────────────┤
│   Web (Puma)   │  Solid Queue   │    Solid Cable         │
│  Turbo/Stimulus│  (Background)  │    (WebSocket)         │
└───────┬────────┴───────┬────────┴────────────────────────┘
        │                │
        ▼                ▼
┌──────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  QuoteFetcher → YahooFinanceClient → SignalDetector     │
│  NewsFetcher → SentimentAnalyzer                        │
│  PolymarketClient                                       │
│  WatchlistScorer                                        │
│  PortfolioService                                       │
│  ExporterService                                        │
└───────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│               PostgreSQL Database                        │
│  users │ assets │ quotes │ portfolios │ positions │ ...  │
└──────────────────────────────────────────────────────────┘
```

### Proposed Architecture with Alerts
```
┌──────────────────────────────────────────────────────────┐
│                      Dracma (Rails 8)                    │
├──────────┬──────────┬──────────┬─────────────────────────┤
│  Web UI  │  JSON API│  Workers │  Cable (WebSocket)      │
└────┬─────┴────┬─────┴────┬─────┴─────────────────────────┘
     │          │          │
     ▼          ▼          ▼
┌──────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  QuoteFetcher, SignalDetector, WatchlistScorer, ...      │
│  AlertDetector (new), TelegramNotifier (new)             │
│  DataHealthChecker (new)                                 │
└───────────────────────┬──────────────────────────────────┘
                        │
          ┌─────────────┼──────────────┐
          ▼             ▼              ▼
    ┌──────────┐ ┌────────────┐ ┌────────────┐
    │ PostgreSQL│ │  Telegram  │ │   Email    │
    │          │ │  Bot API   │ │ (ActionMail)│
    └──────────┘ └────────────┘ └────────────┘
```

---

## Session Continuation Prompt

Use this prompt to continue development:

```
I'm working on Dracma, a Brazilian stock market tracker and portfolio manager built with Rails 8.

Current state (v1.0 — 2026-02-20):
- 128 assets (101 BR + 20 US stocks + 4 commodities + 2 crypto + 1 currency)
- Yahoo Finance fetching with backoff/retry
- Technical indicators, fundamentals, 10 trading signals
- Bilingual news sentiment (PT-BR + EN)
- Polymarket prediction market sentiment
- Algorithmic watchlist scoring
- Web UI: Hotwire (Turbo + Stimulus) + Tailwind CSS v4
- Multi-user Google OAuth, PostgreSQL, Solid Queue
- Portfolio tracking with P&L, dividends, positions
- Exports: CSV, JSON, Markdown, AI JSON
- Sorbet type checking on all services (# typed: true)
- RuboCop (Rails Omakase) + Brakeman + Minitest

Check ROADMAP.md for detailed feature plans.
Check CONTRIBUTING.md for coding conventions and guidelines.

I want to work on: [FEATURE NAME]
```

---

## Development Commands

```bash
# Start development server (Rails + Tailwind watch)
bin/dev

# Fetch quotes (via Rails console)
rails runner "QuoteFetcher.new.fetch_all"

# Generate reports (via Rails console)
rails runner "ExporterService.export_csv; ExporterService.export_json; ExporterService.export_report; ExporterService.export_ai_report"

# Run full test suite
bin/rails test

# Run specific test file
bin/rails test test/services/signal_detector_test.rb

# Lint
bundle exec rubocop
bundle exec rubocop -A  # auto-fix

# Security scan
bin/brakeman

# Type checking
bundle exec srb tc

# Generate Sorbet RBIs
bin/tapioca gems
bin/tapioca dsl
bin/tapioca annotations

# Docker development
docker compose up

# Docker production (via Kamal)
kamal setup    # first deploy
kamal deploy   # subsequent deploys
```

---

*Migrated from [b3_tracker](../b3_tracker) ROADMAP.md and adapted for Ruby on Rails.*
*Last updated: 2026-02-20*
