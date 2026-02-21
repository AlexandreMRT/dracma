# Dracma — AI Agent Development Guide

> Every convention, pattern, and rule documented here is derived from the actual codebase.
> Follow these guidelines exactly when generating, modifying, or reviewing code.
> For full details, see CONTRIBUTING.md in the project root.

---

## Project Overview

Dracma is a Brazilian stock market (B3) tracker and portfolio manager built with **Rails 8.1.2** (Ruby 3.3+, PostgreSQL 16). Migrated from a Python/FastAPI application (`b3_tracker`).

**Stack:** Hotwire (Turbo + Stimulus), Tailwind CSS v4, Propshaft, Importmap (no webpack/esbuild), Solid Queue/Cache/Cable, Sorbet, RuboCop (Rails Omakase), Brakeman, Minitest.

**Key architectural decisions:**
- **Service-object pattern** — all business logic lives in `app/services/`, controllers are thin
- **Sorbet typing** — all services use `# typed: true` with full method signatures
- **Hash-based data flow** — quote data flows as `Hash[Symbol, T.untyped]` through the pipeline
- **Static asset catalog** — assets defined as frozen hashes in `AssetCatalog`, not in DB
- **English code** — all code, comments, and variable names are in English

---

## Mandatory Rules

### 1. Service Files — Always Use Sorbet

Every file in `app/services/` MUST start with:
```ruby
# frozen_string_literal: true
# typed: true
```

Every service MUST use `extend T::Sig` and have Sorbet signatures on **all** methods:
```ruby
module MyService
  extend T::Sig

  sig { params(data: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def self.process(data)
    # ...
  end
end
```

**Two service patterns used:**
- **Module** (stateless, class methods only): `SignalDetector`, `WatchlistScorer`, `SentimentAnalyzer`, `ExporterService`, `PortfolioService`
- **Class** (stateful, instance state): `QuoteFetcher`, `YahooFinanceClient`, `NewsFetcher`, `PolymarketClient`

**Common Sorbet types:**

| Ruby Type | Sorbet Annotation |
|-----------|------------------|
| Hash with symbol keys | `T::Hash[Symbol, T.untyped]` |
| Array of hashes | `T::Array[T::Hash[Symbol, T.untyped]]` |
| Nullable float | `T.nilable(Float)` |
| String or nil | `T.nilable(String)` |
| Boolean | `T::Boolean` |
| No return value | `void` |

### 2. Controllers — Thin, Delegate to Services

Controllers MUST NOT contain business logic. They only assign instance variables and redirect:
```ruby
class DashboardController < ApplicationController
  def index
    quotes = ExporterService.latest_quotes
    @rows = quotes.map { |q| ExporterService.format_row(q) }
  end
end
```

**Controller patterns from the actual codebase:**
- `before_action :set_portfolio, only: [...]` for resource loading via service
- Rescue `ActiveRecord::RecordInvalid` → re-render form with `status: :unprocessable_entity`
- Use `redirect_to path, notice:` / `alert:` for flash messages
- `send_file` for CSV/JSON downloads in `ExportsController`
- Lookup by id or ticker: `find_by(id:) || find_by(ticker: params[:id].upcase)`

**API controllers** live under `Api::` namespace, inherit from `Api::BaseController`:
```ruby
module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :require_login

    def render_json(data, status: :ok)
      render json: data, status: status
    end
  end
end
```

### 3. Models — Lean with Validations

Models contain associations, validations, enums, and simple class methods only. **No business logic in models.**

Key patterns:
- `validates :field, presence: true, uniqueness: { scope: :parent_id }` for composite uniqueness
- `enum :transaction_type, { buy: 1, sell: 2, dividend: 3, split: 4, merge: 5 }, prefix: true` — integer-backed enums with prefix
- `User.from_omniauth(auth)` — `find_or_initialize_by` + attribute assignment, returns unsaved record
- User has UUID PK (`id: :uuid, default: -> { "gen_random_uuid()" }`)
- All other models use standard bigint PKs

### 4. Testing — Minitest Only

This project uses **Minitest** (NOT RSpec). Key rules:
- WebMock blocks all external HTTP: `WebMock.disable_net_connect!(allow_localhost: true)`
- Auth in integration tests via `login_as(users(:alice))` helper (OmniAuth mock)
- Fixture users: `users(:alice)` and `users(:bob)`; portfolios: `portfolios(:alice_default)`, `portfolios(:bob_default)`
- Fixture assets: `assets(:petr4)`, `assets(:aapl)`
- Tests run in parallel: `parallelize(workers: :number_of_processors)`

**Test file patterns:**
```ruby
# Service test (ActiveSupport::TestCase)
class SignalDetectorTest < ActiveSupport::TestCase
  test "detects RSI oversold" do
    data = { rsi_14: 25.0, week_52_high: 100, week_52_low: 50, close: 55,
             volume_ratio: 1.0, ma_50_above_200: nil, above_ma_50: nil, above_ma_200: nil }
    result = SignalDetector.detect(data)
    assert result.rsi_oversold
  end
end

# Controller test (ActionDispatch::IntegrationTest)
class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  setup { login_as users(:alice) }

  test "create makes new portfolio" do
    assert_difference -> { Portfolio.count }, 1 do
      post portfolios_path, params: { portfolio: { name: "New", is_default: "0" } }
    end
    assert_redirected_to portfolio_path(Portfolio.last)
  end

  test "cannot access other user's portfolio" do
    get portfolio_path(portfolios(:bob_default))
    assert_redirected_to portfolios_path
  end
end
```

**Preferred assertions:** `assert_equal`, `assert_predicate`, `assert_in_delta`, `assert_difference`, `assert_operator`, `assert_response`, `assert_redirected_to`

### 5. Validation Checklist — Run Before Every Commit

```bash
bin/rails test                # Tests (must pass 100%)
bundle exec rubocop           # Linting (0 offenses)
bin/brakeman --no-pager       # Security (0 warnings)
bundle exec srb tc            # Type checking (0 errors)
```

---

## Code Patterns (from actual codebase)

### Hash/ActiveRecord Polymorphic Access

Services must handle data as both Hash (symbol keys) and ActiveRecord objects. Use lambda accessor:
```ruby
# SignalDetector pattern — works with Hash or ActiveRecord
g = ->(key) { data.is_a?(Hash) ? (data[key] || data[key.to_s]) : data.try(key) }
rsi = g.call(:rsi_14)
```

Or dual-key helper (WatchlistScorer pattern):
```ruby
sig { params(row: T::Hash[Symbol, T.untyped], key: Symbol).returns(T.untyped) }
def self.value_for(row, key)
  row[key] || row[key.to_s]
end
```

### Struct for Typed Results

```ruby
# SignalDetector::Result with helper methods on the Struct
Result = Struct.new(:golden_cross, :death_cross, :rsi_oversold, :rsi_overbought,
                    :near_52w_high, :near_52w_low, :volume_spike, :summary,
                    keyword_init: true) do
  def as_db_flags
    { signal_golden_cross: golden_cross ? 1 : 0, ... }
  end
end
```

### Safe Navigation for Numeric Formatting

```ruby
price_brl&.round(2)         # ExporterService pattern
value&.to_f                  # YahooFinanceClient pattern
headline&.slice(0, 500)      # NewsFetcher truncation
```

### Frozen Constants for Configuration

```ruby
MARKET_KEYWORDS = { "BTC-USD" => %w[bitcoin btc], ... }.freeze
POSITIVE_WORDS = { "alta" => 1.5, "lucro" => 1.2, ... }.freeze
```

### Error Handling in External API Calls

```ruby
def self.fetch_data(ticker)
  # ... HTTP call ...
rescue StandardError => e
  Rails.logger.warn("ServiceName error for #{ticker}: #{e.message}")
  []  # or {} — always return safe default
end
```

### Scoring with Reasons Array

```ruby
score = T.let(0.0, Float)
reasons = T.let([], T::Array[String])

if rsi && rsi < 30
  score += 15
  reasons << "RSI oversold (#{rsi.round(1)})"
end
# ... more criteria ...
{ ticker: ticker, score: score.round(1), reasons: reasons }
```

---

## RuboCop Configuration

- Inherits from `rubocop-rails-omakase`
- Plugin: `rubocop-minitest`
- **All Metrics cops are disabled** (MethodLength, AbcSize, ClassLength, etc.) — long service methods are acceptable
- Target Ruby: 3.3
- Excluded: `bin/`, `db/schema.rb`, `db/migrate/`, `vendor/`, `tmp/`
- Style: **double quotes**, trailing commas in multi-line, `do...end` for multi-line blocks

---

## Models Reference

| Model | PK | Key Details |
|-------|----|------------|
| `User` | UUID | `from_omniauth(auth)`, has_many watchlists + portfolios |
| `Asset` | bigint | Unique ticker, has_many quotes, `asset_type` in `%w[stock commodity crypto currency]` |
| `Quote` | bigint | 80+ columns, unique on `(asset_id, quote_date)` |
| `Portfolio` | bigint | belongs_to user, has_many positions + transactions |
| `Position` | bigint | Unique on `(portfolio_id, ticker)`, tracks quantity + avg_price_brl |
| `Transaction` | bigint | Enum: `{ buy: 1, sell: 2, dividend: 3, split: 4, merge: 5 }` |
| `Watchlist` | bigint | Unique on `(user_id, ticker)` |

---

## Services Reference

| Service | Type | Purpose |
|---------|------|---------|
| `AssetCatalog` | Module | 128 tracked assets (frozen hash catalog with `IBOVESPA_STOCKS`) |
| `QuoteFetcher` | Class | Orchestrates: fetch → detect → save |
| `YahooFinanceClient` | Class | Yahoo Finance API with retry/backoff (MAX_RETRIES=5) |
| `SignalDetector` | Module | 10 signal types → bullish/bearish/neutral via `Result` Struct |
| `WatchlistScorer` | Module | Composite scoring (RSI + trend + news + sentiment) with reasons |
| `NewsFetcher` | Class | Google News RSS (PT + EN), returns `Array[Hash[Symbol, String]]` |
| `SentimentAnalyzer` | Module | VADER-inspired bilingual scoring, soft normalization |
| `PolymarketClient` | Class | Prediction market sentiment via Gamma API |
| `PortfolioService` | Module | Portfolio CRUD + P&L + position recalculation |
| `ExporterService` | Module | CSV/JSON/MD/AI report, `latest_quotes` + `format_row` |

---

## Frontend — Hotwire + Stimulus + Tailwind

- **Importmap** for JS (no bundler): `pin_all_from "app/javascript/controllers"` 
- **Stimulus controllers** in `app/javascript/controllers/`:
  - `flash_controller.js` — auto-dismiss flash messages after delay, with fade-out transition
  - `sortable_controller.js` — client-side table sorting with numeric/locale-aware comparison
  - `confirm_controller.js` — native `window.confirm()` on destructive actions
  - `auto_refresh_controller.js` — poll via `fetch()` + Turbo Stream at configurable interval
- **Stimulus conventions:** use `static values` for config, `static targets` for DOM refs, `connect()`/`disconnect()` lifecycle
- **Tailwind CSS v4** with dark theme (`bg-gray-900 text-gray-100`), emerald accent (`text-emerald-400`)
- **ERB views** — no ViewComponent or Phlex; standard Rails partials
- **Layout** flash messages use `data-controller="flash"` with configurable delay values

---

## Routes

```ruby
# Auth: get "login", get/delete auth callbacks
# Dashboard: root "dashboard#index"
# Resources: assets (as "instruments"), quotes, watchlists, portfolios > positions + transactions
# Exports: exports#index, exports#csv, exports#json, exports#report
# API namespace: api/quotes, api/signals, api/scoring
# Health: get "up"
```

---

## Background Jobs (Solid Queue)

| Job | Schedule | Action |
|-----|----------|--------|
| `FetchQuotesJob` | Weekdays 10:00, 14:00, 18:00 BRT | `QuoteFetcher.new.fetch_all` |
| `GenerateReportsJob` | Weekdays 18:30 BRT | Export CSV, JSON, MD, AI reports |

---

## Authentication

- Google OAuth 2.0 via OmniAuth
- `ApplicationController` enforces `require_login` globally via `before_action`
- Session-based (`session[:user_id]`), `current_user` memoized with `@current_user ||=`
- `helper_method :current_user, :logged_in?` — available in views
- Skip auth: `skip_before_action :require_login, only: [...]`
- Only `/login` and `/auth/*` routes skip auth

---

## Database Conventions

- PostgreSQL 16 with `enable_extension "pg_catalog.plpgsql"`
- Composite unique indexes: `index_quotes_on_asset_id_and_quote_date`, `index_positions_on_portfolio_id_and_ticker`, `index_watchlists_on_user_id_and_ticker`
- Foreign keys enforced at DB level: `add_foreign_key :portfolios, :users`
- Use `float` for financial values (not `decimal` — this is intentional for the tracker use case)
- Integer columns for boolean signal flags: `signal_golden_cross`, `signal_rsi_oversold` (0/1)
- `quote_date` is `datetime`, not `date`

---

## When Adding New Features

- [ ] Service has `# frozen_string_literal: true` and `# typed: true`
- [ ] Service uses `extend T::Sig` with signatures on **every** method (including private)
- [ ] Controller is thin — logic delegated to service
- [ ] Test file created with meaningful test cases (both happy path and edge cases)
- [ ] Fixtures updated if new models added
- [ ] Migration created if schema changes needed
- [ ] Route added in `config/routes.rb`
- [ ] `bin/tapioca dsl` run if new ActiveRecord models added
- [ ] Stimulus controller follows `*_controller.js` naming with `static values`/`targets`
- [ ] All 4 validation commands pass

---

## Key Files to Reference

| File | Purpose |
|------|---------|
| `ROADMAP.md` | Feature plans and priorities |
| `CONTRIBUTING.md` | Full detailed conventions guide (1300+ lines) |
| `.rubocop.yml` | Linting configuration |
| `sorbet/config` | Type checking ignores |
| `config/routes.rb` | All routes |
| `config/recurring.yml` | Job schedule |
| `test/test_helper.rb` | Test setup, `login_as`, WebMock, parallel config |
| `db/schema.rb` | Full database schema (80+ Quote columns) |
