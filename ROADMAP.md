# Dracma — Roadmap & Future Plans

> This file is structured for AI consumption. Use it to continue development in future sessions.

## Current State (v1.1 — 2026-03-19)

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
- [x] **RuboCop** — Rails Omakase + rubocop-minitest
- [x] **Brakeman** — static security analysis
- [x] **Test suite** — Minitest + WebMock + fixtures, parallel execution
- [x] Stimulus controllers: flash (auto-dismiss), auto_refresh, confirm, sortable
- [x] JSON API namespace: `/api/quotes`, `/api/signals`, `/api/scoring`
- [x] Expanded JSON API: sectors, movers, news, report, refresh, watchlist, portfolios, positions, transactions, performance
- [x] Data health endpoint: `/api/health/data`
- [x] Data health summary embedded in exporter reports (Markdown/AI JSON) + scheduled `HealthCheckJob`
- [x] Weekly market summary email (Action Mailer, Fridays 18:30)
- [x] Benjamin Graham valuation multiples (Graham Number, Graham Multiple, Margin of Safety) computed per quote and exposed in exports/API/instrument detail page
- [x] Parallel quote fetching with configurable worker pool (`QUOTE_FETCHER_CONCURRENCY`)
- [x] Rake task suite: `quotes:*` and `export:*`

### Tech Stack

- Ruby 3.3+ / Rails 8.1.2
- PostgreSQL 16 (+ Solid Cache, Solid Queue, Solid Cable)
- Hotwire (Turbo + Stimulus) + Tailwind CSS v4
- Propshaft + Importmap (no webpack/esbuild)
- RuboCop for linting and Brakeman for security
- Minitest + WebMock + Capybara for testing
- Kamal + Docker for deployment

---

## Priority Features (Next Up)

### 1. Parallel Quote Fetching ⚡
**Status: DONE (2026-03-19)**

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
**Status: DONE (2026-03-19)**

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
**Status: DONE (2026-03-19)**

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
**Status: DONE (2026-03-19)**

Automate testing, linting, and security checks on every push.

**GitHub Actions workflow:**
```yaml
# .github/workflows/ci.yml
jobs:
  test:
    - bin/rails test
    - bundle exec rubocop
    - bin/brakeman --no-pager
```

**Files to create:**
- `.github/workflows/ci.yml`

---

### 6. Increase Test Coverage 🧪
**Priority: HIGH | Effort: MEDIUM | Status: IN PROGRESS**

Current test suite covers models, some services, and controllers. Target: 80%+ coverage.

**Missing test coverage:**
- [x] `QuoteFetcher` service (HTTP mocking with WebMock)
- [x] `NewsFetcher` service (RSS feed mocking)
- [x] `PolymarketClient` service (API mocking)
- [x] `YahooFinanceClient` service (rate limiting, retries, error handling)
- [x] `ExporterService` (CSV/JSON/report generation)
- [ ] Integration tests for dashboard with data
- [x] System tests with Capybara (login flow, portfolio CRUD, watchlist management)

**System tests added (2026-03-28):**
- `test/system/login_test.rb` — login/logout flow, auth redirects
- `test/system/dashboard_test.rb` — dashboard market overview and signals
- `test/system/watchlist_test.rb` — add/remove ticker, list display
- `test/system/portfolio_test.rb` — portfolio CRUD, access control, performance view

**Note:** System tests require Chrome or Firefox + matching webdriver. They run in CI (GitHub Actions) where Chrome is pre-installed.

**Files created:**
- `test/system/login_test.rb`
- `test/system/dashboard_test.rb`
- `test/system/watchlist_test.rb`
- `test/system/portfolio_test.rb`
- `test/application_system_test_case.rb` (updated with `sign_in_as` helper)

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
**Status: DONE (2026-07-24)**

Ensure data reliability before downstream analysis:
- Detect stale quotes (last update older than N hours)
- Missing/NaN fields per asset and per source
- Outlier detection on price/volume changes
- Market session anomalies (e.g., extreme spikes)
- Daily health report + alerts

**Implementation notes:**
- `DataHealthChecker` service + `/api/health/data` endpoint with tests
- `ExporterService.report_data` now embeds the health report under `:health`; the AI JSON report exposes it as `data_health`, and the Markdown report has a "Data Health" section
- `HealthCheckJob` runs the checker on a schedule and logs `warning`/`critical` statuses (foundation for future alerting, e.g. Telegram)
- `config/recurring.yml` runs the job weekdays at 18:45 (after quote fetch + report generation)

**Files created/modified:**
- `app/services/data_health_checker.rb`
- `app/controllers/api/health_controller.rb`
- `app/jobs/health_check_job.rb`
- `app/services/exporter_service.rb` (health summary in report/AI/Markdown outputs)
- `config/recurring.yml`

---

### 9. Weekly Email Report 📧
**Status: DONE (2026-03-28)**

Send summary email every Friday after market close:
- Week's top gainers/losers
- New signals detected
- News sentiment summary
- Portfolio performance

**Implementation notes:**
- Action Mailer with `WeeklyReportMailer.weekly_summary(user)`
- `app/views/weekly_report_mailer/weekly_summary.html.erb`
- `WeeklyEmailJob` enqueued for every `User` via `find_each`
- Scheduled Fridays at 18:30 in `config/recurring.yml`

**Files:**
- `app/mailers/weekly_report_mailer.rb`
- `app/views/weekly_report_mailer/weekly_summary.html.erb`
- `app/jobs/weekly_email_job.rb`
- `config/recurring.yml`

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

### 11. Graham Valuation Multiples 📐
**Status: DONE (2026-07-24)**

Benjamin Graham value-investing multiples, computed per quote:
- Graham Number: √(22.5 × EPS × Book Value per Share)
- Graham Multiple: P/E × P/B (Graham's rule of thumb threshold is 22.5)
- Margin of Safety: (Graham Number − Price) / Graham Number × 100

**Implementation notes:**
- New `GrahamValuation` module (pure calculation, no DB access) — returns `nil` for any
  metric when the required inputs (EPS, P/B, P/E, price) are missing or non-positive,
  rather than fabricating a value
- Wired into `QuoteFetcher#fetch_single`, persisted via 3 new `Quote` columns
- Exposed in `ExporterService.format_row` and in the AI JSON report under
  `assets[].fundamentals.graham_valuation`
- Automatically available through `/api/quotes` (backed by `ApiDataService` → `ExporterService`)

**Files created/modified:**
- `app/services/graham_valuation.rb` (new)
- `app/services/quote_fetcher.rb` (calculate + persist)
- `app/services/exporter_service.rb` (format_row + AI report fundamentals)
- `db/migrate/20260724185718_add_graham_fields_to_quotes.rb` (new columns)
- `test/services/graham_valuation_test.rb` (new)

---

### 12. Signal Performance Tracker & Adaptive Scoring 🎯
**Priority: HIGH | Effort: HIGH | Status: PLANNED (design finalized 2026-07-24)**

Supersedes the old "Backtesting Engine" backlog idea (see note in Backlog section).
Goal: measure how good our own signals/reports actually are, then use that feedback
to tune `WatchlistScorer` weights — with humans in the loop before anything changes.

**Design (finalized via stakeholder Q&A on 2026-07-24):**

1. **What gets measured** — every signal/prediction type we currently produce:
   - Technical signals (golden/death cross, RSI oversold/overbought, 52w high/low, volume spike)
   - News/sentiment label (positive/negative) vs subsequent price movement
   - `WatchlistScorer` composite score — do high-scored picks actually outperform?

2. **Comparison baseline** — for each signal that fired on day X, evaluate at day X+7
   and X+30:
   - Raw price movement (did it move in the predicted direction?)
   - Benchmark-relative movement (alpha vs IBOV/S&P 500 over the same window) — a
     "bullish" call that merely tracked the market isn't a real win

3. **Data source** — recompute directly from `Quote` history in the DB (reliable,
   always queryable), cross-checked against archived `exports/*.json` AI reports
   when available (validates that what was reported matches what the DB shows —
   catches drift/bugs between the two)

4. **Start now, don't wait** — begin accumulating measurement data immediately with
   whatever history exists (rather than gating on 6+ months as originally scoped).
   Confidence naturally improves as more history accumulates.

5. **Evaluation horizons** — 1 week and 1 month after a signal fires (not 1 day —
   too noisy; a fully custom/configurable horizon is a later refinement, not v1)

6. **Output surfaces:**
   - New dashboard page/section (e.g. `/signals/performance`) — win-rate per signal
     type, sortable
   - New API endpoint (e.g. `/api/signals/performance`) — for AI/programmatic consumption
   - New section in the scheduled Markdown/AI report — "Signal Track Record"

7. **Adaptive scoring (the ambitious part)** — automatically propose `WatchlistScorer`
   weight adjustments based on measured performance, with guardrails since this feeds
   AI reports/decisions:
   - **Human-approved changes** — a proposed weight adjustment is generated, but only
     applied after a human reviews and approves it (no silent auto-apply)
   - **Minimum sample size gate** — a signal type needs ≥30 resolved (evaluated)
     occurrences before its weight can be adjusted at all
   - **Max change per cycle** — cap any single weight's shift to roughly ±10% per
     tuning cycle, to prevent overfitting/whiplash from a lucky/unlucky streak
   - **Monthly cadence** — re-evaluate performance and generate proposals once a
     month via a scheduled job, not continuously

**Proposed architecture:**
- `SignalOutcome` model — one row per (asset, signal_type, fired_at); captures the
  signal snapshot, then resolves `price_change_1w`/`price_change_1m` +
  benchmark-relative alpha once the horizon passes
- `SignalPerformanceEvaluator` service — walks `Quote` history, finds where each
  signal fired historically (via the existing `signal_*` columns), computes actual
  forward returns, upserts `SignalOutcome` rows
- `ScoringWeightProposal` model — stores a proposed weight delta set + the
  performance data that justified it + approval status (pending/approved/rejected)
  + `applied_at`
- `ScoringWeightTuner` service — monthly job reads resolved `SignalOutcome`s,
  generates a `ScoringWeightProposal` (respecting min sample size + max change
  caps); does NOT auto-apply
- Human approval UI — a simple page listing pending proposals with before/after
  weights and the supporting win-rate data; approving updates `WatchlistScorer`'s
  active weights (this likely requires moving the current hardcoded weights into
  a DB-backed or config-backed store first)
- `app/controllers/signals_performance_controller.rb` + `/signals/performance` view
- `app/controllers/api/signal_performance_controller.rb` + `/api/signals/performance`
- `ExporterService` — add a "Signal Track Record" section to Markdown/AI reports
- Scheduled jobs: `EvaluateSignalPerformanceJob` (daily, resolves matured outcomes)
  + `ProposeScoringWeightsJob` (monthly, generates proposals)

**Open implementation questions for whoever picks this up:**
- Where `WatchlistScorer`'s weights currently live (hardcoded constants) — they
  need to be extracted into something adjustable before auto-tuning is possible
- Need a `SignalOutcome` migration; decide uniqueness constraint, likely
  `(asset_id, signal_type, fired_at)`
- How "benchmark-relative alpha" is computed for non-stock asset types
  (commodities/crypto/currency don't have `vs_ibov`/`vs_sp500` comparisons — may
  need to exclude them or use a different baseline, e.g. crypto vs a crypto index)

**Files to create:**
- `db/migrate/xxx_create_signal_outcomes.rb`
- `db/migrate/xxx_create_scoring_weight_proposals.rb`
- `app/models/signal_outcome.rb`
- `app/models/scoring_weight_proposal.rb`
- `app/services/signal_performance_evaluator.rb`
- `app/services/scoring_weight_tuner.rb`
- `app/jobs/evaluate_signal_performance_job.rb`
- `app/jobs/propose_scoring_weights_job.rb`
- `app/controllers/signals_performance_controller.rb`
- `app/controllers/api/signal_performance_controller.rb`
- `app/views/signals_performance/index.html.erb`
- `config/recurring.yml` (daily evaluation + monthly proposal generation)


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
**Superseded by item 12 ("Signal Performance Tracker & Adaptive Scoring") above.**
The original idea here (win rate, Sharpe ratio, vs buy-and-hold) is now folded into
that item's fully-specced design — see the Priority Features section.

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

# Docker development
docker compose up

# Docker production (via Kamal)
kamal setup    # first deploy
kamal deploy   # subsequent deploys
```

---

*Migrated from [b3_tracker](../b3_tracker) ROADMAP.md and adapted for Ruby on Rails.*
*Last updated: 2026-03-19*
