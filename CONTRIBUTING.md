# Contributing to Dracma — AI Agent Development Guide

> This file serves as the definitive reference for AI coding agents working on this project.
> Every convention, pattern, and rule documented here is derived from the actual codebase.
> Follow these guidelines exactly when generating, modifying, or reviewing code.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [File Structure & Naming](#file-structure--naming)
3. [Ruby & Rails Conventions](#ruby--rails-conventions)
4. [Sorbet Type Checking](#sorbet-type-checking)
5. [RuboCop Linting](#rubocop-linting)
6. [Brakeman Security](#brakeman-security)
7. [Testing with Minitest](#testing-with-minitest)
8. [Service Object Pattern](#service-object-pattern)
9. [Controller Conventions](#controller-conventions)
10. [Model Conventions](#model-conventions)
11. [Frontend Conventions](#frontend-conventions)
12. [Database Conventions](#database-conventions)
13. [Background Jobs](#background-jobs)
14. [API Design](#api-design)
15. [Data Flow & Architecture](#data-flow--architecture)
16. [Export & Reporting](#export--reporting)
17. [Authentication](#authentication)
18. [Deployment](#deployment)
19. [Validation Checklist](#validation-checklist)

---

## Project Overview

Dracma is a Brazilian stock market (B3) tracker and portfolio manager built with **Rails 8.1.2**. It was migrated from a Python/FastAPI application (`b3_tracker`).

**Core capabilities:**
- Fetches real-time quotes from Yahoo Finance for 128 assets
- Detects 10 types of trading signals (RSI, crosses, volume, news)
- Scores watchlists with a composite algorithm
- Analyzes news sentiment in Portuguese and English
- Integrates Polymarket prediction market data
- Manages multi-user portfolios with P&L tracking
- Exports CSV, JSON, Markdown, and AI-structured reports

**Key architectural decisions:**
- **Service-object pattern** — all business logic lives in `app/services/`, controllers are thin
- **Sorbet typing** — all services use `# typed: true` with full method signatures
- **Hash-based data flow** — quote data flows as `Hash[Symbol, T.untyped]` through the pipeline
- **Static asset catalog** — assets defined as frozen hashes in `AssetCatalog`, not hardcoded in DB
- **Portuguese export labels** — exported field names use Portuguese (`preco_brl`, `setor`, `var_1d`)
- **English code** — all code, comments, and variable names are in English

---

## File Structure & Naming

```
app/
├── controllers/              # Rails controllers (thin, delegate to services)
│   ├── api/                  # JSON API controllers (inherit from Api::BaseController)
│   │   ├── base_controller.rb
│   │   ├── quotes_controller.rb
│   │   ├── scoring_controller.rb
│   │   └── signals_controller.rb
│   ├── application_controller.rb
│   ├── dashboard_controller.rb
│   ├── exports_controller.rb
│   ├── portfolios_controller.rb
│   ├── positions_controller.rb
│   ├── sessions_controller.rb
│   ├── transactions_controller.rb
│   └── watchlists_controller.rb
├── javascript/controllers/   # Stimulus JS controllers
├── jobs/                     # Solid Queue background jobs
├── models/                   # ActiveRecord models
├── services/                 # Business logic (Sorbet-typed)
└── views/                    # ERB templates + Tailwind CSS v4

config/
├── routes.rb                 # All routes (RESTful + API namespace)
├── recurring.yml             # Solid Queue cron schedule
└── initializers/
    └── omniauth.rb           # Google OAuth2

test/
├── test_helper.rb            # WebMock, OmniAuth test mode, login_as helper
├── controllers/              # Controller integration tests
├── models/                   # Model unit tests
├── services/                 # Service unit tests
├── fixtures/                 # YAML fixtures for all models
├── integration/              # Integration tests
└── system/                   # Capybara system tests
```

### Naming Rules

| Type | Convention | Example |
|------|-----------|---------|
| Service (module) | `PascalCase` module | `SignalDetector`, `WatchlistScorer` |
| Service (class) | `PascalCase` class | `QuoteFetcher`, `PortfolioService` |
| Controller | `PascalCaseController` | `DashboardController` |
| Model | singular `PascalCase` | `Quote`, `Portfolio` |
| Test file | `*_test.rb` under matching dir | `test/services/signal_detector_test.rb` |
| Migration | `db/migrate/YYYYMMDDHHMMSS_*.rb` | `20260220000000_create_assets.rb` |
| Rake task | `lib/tasks/*.rake` | `lib/tasks/quotes.rake` |
| Fixture | plural model name `.yml` | `test/fixtures/quotes.yml` |

---

## Ruby & Rails Conventions

### Required File Headers

Every Ruby file in `app/services/` MUST start with:

```ruby
# frozen_string_literal: true
# typed: true
```

Every other Ruby file (controllers, models, jobs) MUST start with:

```ruby
# frozen_string_literal: true is NOT required (Rails convention — omitted in generated files)
```

> **Note:** Rails-generated files (controllers, models) do not use `frozen_string_literal`. Services do because they were ported from a Python codebase with stricter conventions. Follow the existing pattern: if the file is in `app/services/`, add both pragmas. Otherwise, follow Rails defaults.

### String Style

- Use **double quotes** for strings (Rails Omakase default)
- Single quotes are acceptable for simple strings but double quotes are preferred for consistency

### Hash Style

- Use **symbol keys** for internal data: `{ ticker: "PETR4", price: 42.50 }`
- Use **string keys** only when parsing external JSON/API responses

### Method Style

- Use `def method_name` (snake_case)
- Prefer `do...end` for multi-line blocks, `{ }` for single-line
- Use trailing comma in multi-line arrays and hashes (Rails Omakase)

### Rails Version

- **Rails 8.1.2** with `config.load_defaults 8.0`
- Active Storage, Action Mailbox, and Action Text are **not loaded** (removed from `config/application.rb`)
- Uses Propshaft (not Sprockets) for assets

---

## Sorbet Type Checking

### When to Use Sorbet

| File Type | Sorbet Required? | Typing Level |
|-----------|-----------------|--------------|
| Services (`app/services/`) | **Yes** | `# typed: true` |
| Controllers | No | N/A |
| Models | No | N/A |
| Jobs | No | N/A |
| Tests | No (ignored in sorbet/config) | N/A |

### Service Typing Pattern

Every service MUST follow this pattern:

```ruby
# frozen_string_literal: true
# typed: true

# Brief description of the service.
# Ported from Python <original_filename>.py (if applicable).
module MyService
  extend T::Sig

  # Constants go here
  SOME_THRESHOLD = 0.5

  # Every public method needs a signature
  sig { params(data: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def self.process(data)
    # implementation
  end

  # Private methods also need signatures
  sig { params(value: T.nilable(Float)).returns(Float) }
  private_class_method def self.safe_float(value)
    value || 0.0
  end
end
```

### Sorbet Patterns Used in This Codebase

**Module with class methods** (stateless services):
```ruby
module SignalDetector
  extend T::Sig

  sig { params(data: T::Hash[Symbol, T.untyped]).returns(SignalDetector::Result) }
  def self.detect(data)
    # ...
  end
end
```

**Class with instance methods** (stateful services):
```ruby
class QuoteFetcher
  extend T::Sig

  sig { void }
  def initialize
    @logger = Rails.logger
  end

  sig { returns([Integer, Integer]) }
  def fetch_all
    # ...
  end
end
```

### Common Sorbet Types

| Ruby Type | Sorbet Annotation |
|-----------|------------------|
| Hash with symbol keys | `T::Hash[Symbol, T.untyped]` |
| Array of hashes | `T::Array[T::Hash[Symbol, T.untyped]]` |
| Nullable float | `T.nilable(Float)` |
| String or nil | `T.nilable(String)` |
| Integer | `Integer` |
| Boolean | `T::Boolean` |
| No return value | `void` |
| Tuple return | `[Integer, Integer]` |
| Any type | `T.untyped` |

### Sorbet Commands

```bash
# Type check the entire project
bundle exec srb tc

# Generate RBIs for gems
bin/tapioca gems

# Generate RBIs for DSLs (ActiveRecord, etc.)
bin/tapioca dsl

# Generate RBIs for annotations
bin/tapioca annotations
```

### Sorbet Config (`sorbet/config`)

The following paths are **ignored** by Sorbet:
- `tmp/`, `vendor/bundle`, `db/migrate/`, `test/`
- `sorbet/rbi/sorbet-typed`
- Several specific gem RBIs that cause issues (json, bigdecimal, msgpack, irb, net-http, logger, csv, matrix, net-protocol, rubyzip, pp)

**When adding new gem dependencies:** If Sorbet fails on a generated RBI file, add `--ignore=sorbet/rbi/gems/<gem_file>.rbi` to `sorbet/config`.

---

## RuboCop Linting

### Configuration (`.rubocop.yml`)

```yaml
inherit_gem: { rubocop-rails-omakase: rubocop.yml }
plugins:
  - rubocop-minitest

AllCops:
  TargetRubyVersion: 3.3
  NewCops: enable
  Exclude:
    - "bin/**/*"
    - "db/schema.rb"
    - "db/migrate/**/*"
    - "node_modules/**/*"
    - "vendor/**/*"
    - "tmp/**/*"
    - "storage/**/*"
```

### Disabled Cops

**All Metrics cops are disabled** — this is intentional because services contain complex financial logic that naturally produces long methods:

| Cop | Status | Reason |
|-----|--------|--------|
| `Metrics/MethodLength` | **Disabled** | Services have long orchestration methods |
| `Metrics/AbcSize` | **Disabled** | Complex financial calculations |
| `Metrics/ClassLength` | **Disabled** | Services can be large |
| `Metrics/ModuleLength` | **Disabled** | Modules can be large |
| `Metrics/BlockLength` | **Disabled** | Test blocks can be lengthy |
| `Metrics/CyclomaticComplexity` | **Disabled** | Signal detection has many branches |
| `Metrics/PerceivedComplexity` | **Disabled** | Same as above |
| `Metrics/ParameterLists` | **Disabled** | Some methods need many params |
| `Naming/MethodParameterName` | **Disabled** | Allow short param names (e.g., `q`, `r`) |

### Minitest Cops

```yaml
Minitest/AssertEmptyLiteral:
  Enabled: true

Minitest/RefuteFalse:
  Enabled: true

Minitest/MultipleAssertions:
  Max: 10  # Allow up to 10 assertions per test method
```

### Running RuboCop

```bash
# Check all files
bundle exec rubocop

# Auto-fix safe corrections
bundle exec rubocop -A

# Check specific file
bundle exec rubocop app/services/my_service.rb

# Show only offenses (no passing files)
bundle exec rubocop --format simple
```

### Key Style Rules (from Rails Omakase)

- Double quotes for strings
- Trailing commas in multi-line literals
- `do...end` for multi-line blocks
- No parentheses on no-argument method definitions
- Use `%w[]` for word arrays, `%i[]` for symbol arrays
- Use `&&` / `||` (not `and` / `or`)
- Use `unless` instead of `if !`
- Prefer `each` over `for`

---

## Brakeman Security

Brakeman is used for static security analysis. **Zero warnings is the standard.**

```bash
# Run security scan
bin/brakeman

# Run with no-pager (for CI)
bin/brakeman --no-pager

# Run and exit with error code on warnings
bin/brakeman -z
```

### Common Issues to Watch For

- **SQL injection** — always use parameterized queries or ActiveRecord methods
- **Mass assignment** — use strong parameters in controllers
- **Cross-site scripting** — default ERB escaping handles most cases; be careful with `raw` and `html_safe`
- **CSRF** — enabled globally; API controllers explicitly skip via `skip_before_action :verify_authenticity_token`

---

## Testing with Minitest

### Framework & Setup

- **Framework:** Minitest (NOT RSpec — this project uses Minitest exclusively)
- **HTTP mocking:** WebMock (all external HTTP disabled except localhost)
- **Fixtures:** YAML fixtures in `test/fixtures/`
- **Parallelization:** `parallelize(workers: :number_of_processors)`
- **Auth testing:** OmniAuth test mode with mock auth hashes

### Test Helper (`test/test_helper.rb`)

Key features of the test setup:
```ruby
# WebMock blocks all external HTTP
WebMock.disable_net_connect!(allow_localhost: true)

# OmniAuth test mode enabled globally
OmniAuth.config.test_mode = true

# login_as helper for controller tests
class ActionDispatch::IntegrationTest
  def login_as(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: user.google_id,
      info: { email: user.email, name: user.name, image: user.picture_url },
    )
    get "/auth/google_oauth2/callback"
  end
end
```

### Test File Structure

```
test/
├── test_helper.rb                    # Setup, WebMock, OmniAuth mock, login_as
├── controllers/
│   ├── dashboard_controller_test.rb  # Test auth redirect + authenticated access
│   ├── exports_controller_test.rb
│   ├── portfolios_controller_test.rb
│   └── ...
├── models/
│   ├── user_test.rb                  # Validations, associations, from_omniauth
│   ├── asset_test.rb
│   ├── quote_test.rb
│   └── ...
├── services/
│   ├── signal_detector_test.rb       # Pure-logic unit tests
│   ├── watchlist_scorer_test.rb
│   ├── sentiment_analyzer_test.rb
│   ├── portfolio_service_test.rb
│   └── asset_catalog_test.rb
├── fixtures/
│   ├── users.yml                     # alice and bob fixture users
│   ├── assets.yml
│   ├── quotes.yml
│   ├── portfolios.yml
│   ├── positions.yml
│   ├── transactions.yml
│   └── watchlists.yml
├── integration/
├── helpers/
├── jobs/
├── mailers/
└── system/                           # Capybara browser tests
```

### Writing Tests

#### Model Tests

```ruby
class UserTest < ActiveSupport::TestCase
  test "validates presence of email" do
    user = User.new(google_id: "123", name: "Test")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "from_omniauth creates user from auth hash" do
    auth = OmniAuth::AuthHash.new(
      uid: "new_google_id",
      info: { email: "new@example.com", name: "New User", image: "http://pic.url" }
    )
    user = User.from_omniauth(auth)
    assert_equal "new@example.com", user.email
  end
end
```

#### Service Tests

```ruby
class SignalDetectorTest < ActiveSupport::TestCase
  test "detects RSI oversold when below threshold" do
    data = { rsi_14: 25.0, ma_50: 100, ma_200: 90 }
    result = SignalDetector.detect(data)
    assert_predicate result, :rsi_oversold
  end

  test "classifies as bullish with 3+ bullish signals" do
    data = build_bullish_data
    result = SignalDetector.detect(data)
    assert_equal "bullish", result.summary
  end
end
```

#### Controller Tests

```ruby
class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not authenticated" do
    get root_path
    assert_redirected_to login_path
  end

  test "shows dashboard when authenticated" do
    login_as(users(:alice))
    get root_path
    assert_response :success
  end
end
```

#### Service Tests with WebMock

```ruby
class QuoteFetcherTest < ActiveSupport::TestCase
  setup do
    stub_request(:get, /query1.finance.yahoo.com/)
      .to_return(status: 200, body: yahoo_response_json, headers: { "Content-Type" => "application/json" })
  end

  test "fetches quote data from Yahoo Finance" do
    fetcher = QuoteFetcher.new
    result = fetcher.send(:fetch_single, { ticker: "PETR4.SA", name: "Petrobras", sector: "Oil", type: "stock" })
    assert_not_nil result
    assert_equal "PETR4.SA", result[:ticker]
  end
end
```

### Assertion Preferences

Use these assertion methods (in order of preference):

| Assertion | Use For |
|-----------|---------|
| `assert_predicate obj, :method?` | Boolean predicates (`valid?`, `empty?`, `nil?`) |
| `assert_equal expected, actual` | Value equality |
| `assert_in_delta expected, actual, delta` | Float comparisons |
| `assert_difference "Model.count", 1` | Database record creation/deletion |
| `assert_operator value, :>, threshold` | Numeric comparisons |
| `assert_nil value` | Nil checks |
| `assert_not_nil value` | Non-nil checks |
| `assert_includes collection, item` | Collection membership |
| `assert_response :success` | HTTP response codes |
| `assert_redirected_to path` | Redirect assertions |

### Fixture Users

Two fixture users are available in all tests:

```yaml
# test/fixtures/users.yml
alice:
  id: "550e8400-e29b-41d4-a716-446655440000"
  google_id: "google_alice_123"
  email: "alice@example.com"
  name: "Alice Test"

bob:
  id: "550e8400-e29b-41d4-a716-446655440001"
  google_id: "google_bob_456"
  email: "bob@example.com"
  name: "Bob Test"
```

Access in tests: `users(:alice)`, `users(:bob)`

### Running Tests

```bash
# Full suite
bin/rails test

# Specific file
bin/rails test test/services/signal_detector_test.rb

# Specific test by name
bin/rails test test/services/signal_detector_test.rb -n test_detects_rsi_oversold

# Verbose output
bin/rails test -v

# With line number
bin/rails test test/models/user_test.rb:10
```

---

## Service Object Pattern

### Design Principles

1. **All business logic goes in `app/services/`** — controllers MUST NOT contain business logic
2. **Services are Sorbet-typed** — `# typed: true` with `extend T::Sig`
3. **Two patterns used:**
   - **Module** for stateless services (only class methods): `SignalDetector`, `WatchlistScorer`, `SentimentAnalyzer`, `AssetCatalog`
   - **Class** for stateful services (hold instance state): `QuoteFetcher`, `PortfolioService`, `YahooFinanceClient`, `NewsFetcher`, `PolymarketClient`, `ExporterService`

### Module Service Template

```ruby
# frozen_string_literal: true
# typed: true

# Brief description of what this service does.
# Ported from Python <filename>.py (if applicable).
module MyService
  extend T::Sig

  # Constants
  THRESHOLD = 0.5

  # Public class method with Sorbet signature
  sig { params(data: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
  def self.process(data)
    value = extract_value(data)
    { result: value }
  end

  # Private helper
  sig { params(data: T::Hash[Symbol, T.untyped]).returns(Float) }
  private_class_method def self.extract_value(data)
    data[:value]&.to_f || 0.0
  end
end
```

### Class Service Template

```ruby
# frozen_string_literal: true
# typed: true

# Brief description of what this service does.
class MyService
  extend T::Sig

  sig { void }
  def initialize
    @logger = Rails.logger
  end

  sig { params(input: String).returns(T::Hash[Symbol, T.untyped]) }
  def perform(input)
    @logger.info("Processing: #{input}")
    # implementation
  end

  private

  sig { params(raw: String).returns(String) }
  def sanitize(raw)
    raw.strip.downcase
  end
end
```

### Existing Services Reference

| Service | Type | Purpose | Key Methods |
|---------|------|---------|-------------|
| `AssetCatalog` | Module | Static asset catalog (frozen hashes) | `.all_assets`, `.find_by_ticker`, `.ibovespa_stocks` |
| `SignalDetector` | Module | Trading signal detection | `.detect(data)` → `Result` struct |
| `WatchlistScorer` | Module | Composite watchlist scoring | `.build(stocks)` → ranked list |
| `SentimentAnalyzer` | Module | Text sentiment analysis | `.analyze(text, lang)` → Float |
| `QuoteFetcher` | Class | Orchestrates full data fetch | `#fetch_all` → `[saved, errors]` |
| `YahooFinanceClient` | Class | Yahoo Finance HTTP client | `#fetch_chart(ticker)`, `#fetch_summary(ticker)` |
| `NewsFetcher` | Class | Google News RSS feeds | `#fetch(ticker, name)` → Hash |
| `PolymarketClient` | Class | Polymarket API client | `#fetch_sentiment` → Hash |
| `PortfolioService` | Class | Portfolio CRUD + P&L | `#create_portfolio`, `#add_transaction`, `#performance` |
| `ExporterService` | Module/Class | Data export (CSV/JSON/MD/AI) | `.export_csv`, `.export_json`, `.export_report` |

### Data Flow Convention

Quote data flows as `Hash[Symbol, T.untyped]` through the pipeline:

```
AssetCatalog (static list)
    ↓
QuoteFetcher.fetch_all
    ↓ calls
YahooFinanceClient.fetch_chart  →  raw OHLCV data
YahooFinanceClient.fetch_summary →  fundamentals
    ↓ calculates
Technical indicators (RSI, MA50, MA200, volatility, volume_ratio)
    ↓ calls
NewsFetcher.fetch  →  news headlines + sentiment
SentimentAnalyzer.analyze  →  sentiment scores
    ↓ calls
PolymarketClient.fetch_sentiment  →  prediction market data
    ↓ calls
SignalDetector.detect  →  signal flags + classification
    ↓ saves
Quote.create!  (ActiveRecord)
    ↓ used by
WatchlistScorer.build  →  ranked watchlist
ExporterService.export_*  →  CSV/JSON/reports
```

### Portuguese Field Names in Exports

Exported data uses Portuguese field names for consistency with the original Python project:

| English (internal) | Portuguese (export) |
|-------------------|-------------------|  
| `price_brl` | `preco_brl` |
| `price_usd` | `preco_usd` |
| `sector` | `setor` |
| `type` | `tipo` |
| `change_1d` | `var_1d` |
| `change_1w` | `var_1w` |
| `change_1m` | `var_1m` |
| `change_ytd` | `var_ytd` |
| `name` | `nome` |
| `quotes` | `cotacoes` |

---

## Controller Conventions

### General Rules

1. **Thin controllers** — delegate ALL logic to services
2. **Global auth** — `ApplicationController` enforces `require_login` for all actions
3. **Skip auth explicitly** — only `PagesController#login` and `SessionsController` skip auth

### ApplicationController

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :require_login
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in to access this section"
    end
  end
end
```

### Web Controller Pattern

```ruby
class MyController < ApplicationController
  def index
    @data = SomeService.fetch_data
  end

  def show
    @item = Model.find(params[:id])
  end

  def create
    @item = SomeService.create(permitted_params)
    if @item.persisted?
      redirect_to @item, notice: "Created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def permitted_params
    params.require(:model).permit(:field1, :field2)
  end
end
```

### API Controller Pattern

All API controllers inherit from `Api::BaseController`:

```ruby
module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token  # No CSRF for JSON API
    before_action :require_login                   # Still requires auth

    private

    def render_json(data, status: :ok)
      render json: data, status: status
    end
  end
end
```

New API controller example:

```ruby
module Api
  class SectorsController < BaseController
    def index
      quotes = ExporterService.latest_quotes
      rows = quotes.map { |q| ExporterService.format_row(q) }
      sectors = rows.group_by { |r| r[:setor] }
                    .transform_values { |stocks| aggregate_sector(stocks) }
      render_json({ sectors: sectors })
    end

    private

    def aggregate_sector(stocks)
      {
        count: stocks.size,
        avg_change_1d: stocks.sum { |s| s[:var_1d] || 0 } / stocks.size.to_f
      }
    end
  end
end
```

---

## Model Conventions

### General Rules

- **Validations** — `presence`, `uniqueness` on key fields
- **Associations** — standard Rails `has_many`, `belongs_to` with `dependent: :destroy`
- **UUID primary keys** — only on `users` table
- **Enums** — use integer-backed enums (e.g., `transaction_type: { buy: 1, sell: 2, ... }`)

### Existing Models

```ruby
# User — UUID primary key, OAuth integration
class User < ApplicationRecord
  has_many :watchlists, dependent: :destroy
  has_many :portfolios, dependent: :destroy
  validates :google_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_omniauth(auth)
    user = find_or_initialize_by(google_id: auth.uid)
    user.email = auth.info.email
    user.name = auth.info.name
    user.picture_url = auth.info.image
    user.last_login = Time.current
    user
  end
end

# Asset — static catalog, created lazily during fetch
class Asset < ApplicationRecord
  has_many :quotes, dependent: :destroy
  validates :ticker, presence: true, uniqueness: true
end

# Quote — 60+ columns, one per asset per day
class Quote < ApplicationRecord
  belongs_to :asset
  validates :quote_date, presence: true
  validates :asset_id, uniqueness: { scope: :quote_date }
end

# Portfolio — per-user, with default flag
class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :positions, dependent: :destroy
  has_many :transactions, dependent: :destroy
end

# Position — unique per (portfolio, ticker)
class Position < ApplicationRecord
  belongs_to :portfolio
  validates :ticker, uniqueness: { scope: :portfolio_id }
end

# Transaction — typed (buy/sell/dividend/split/merge)
class Transaction < ApplicationRecord
  belongs_to :portfolio
  enum :transaction_type, { buy: 1, sell: 2, dividend: 3, split: 4, merge: 5 }
end

# Watchlist — unique per (user, ticker)
class Watchlist < ApplicationRecord
  belongs_to :user
  validates :ticker, uniqueness: { scope: :user_id }
end
```

### Adding New Models

When creating a new model:

1. Generate migration: `bin/rails generate migration CreateModelName`
2. Add model file in `app/models/`
3. Add fixtures in `test/fixtures/model_names.yml`
4. Add model test in `test/models/model_name_test.rb`
5. Run `bin/tapioca dsl` to regenerate Sorbet RBIs

---

## Frontend Conventions

### Stack

- **ERB templates** — `.html.erb` in `app/views/`
- **Tailwind CSS v4** — utility-first CSS framework
- **Hotwire** — Turbo Drive for navigation, Turbo Frames for partial updates
- **Stimulus** — lightweight JS controllers for interactivity
- **Importmap** — no webpack, esbuild, or bundler; JS modules via importmap
- **Propshaft** — asset pipeline (not Sprockets)

### Stimulus Controllers

Located in `app/javascript/controllers/`:

| Controller | Purpose |
|-----------|---------|
| `flash_controller.js` | Auto-dismiss flash messages after timeout |
| `auto_refresh_controller.js` | Periodic page refresh for live data |
| `confirm_controller.js` | Confirmation dialogs for destructive actions |
| `sortable_controller.js` | Client-side table column sorting |

### Adding a New Stimulus Controller

1. Create `app/javascript/controllers/my_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  connect() {
    // runs when controller connects to DOM
  }

  greet() {
    this.outputTarget.textContent = "Hello!"
  }
}
```

2. Register in `app/javascript/controllers/index.js` (auto-loaded by Stimulus)

3. Use in ERB:
```erb
<div data-controller="my">
  <button data-action="click->my#greet">Click me</button>
  <span data-my-target="output"></span>
</div>
```

### Importmap

JavaScript dependencies are managed via `config/importmap.rb`:
```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

To add a new JS dependency:
```bash
bin/importmap pin <package-name>
```

### View Layout

- Main layout: `app/views/layouts/application.html.erb`
- Partials: prefix with `_` (e.g., `_form.html.erb`, `_quote_row.html.erb`)
- Use Turbo Frames for in-page updates: `<turbo-frame id="...">`

---

## Database Conventions

### General Rules

- **PostgreSQL only** — no SQLite support (except tests if needed)
- **UUID primary keys** — only on `users` table (all others use auto-increment integer)
- **Composite unique constraints** — used on: `(asset_id, quote_date)`, `(portfolio_id, ticker)`, `(user_id, ticker)`
- **Foreign keys** — always use `references` or `add_foreign_key` in migrations
- **Timestamps** — all tables have `created_at` and `updated_at`

### Migration Style

```ruby
class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :ticker, null: false
      t.string :name, null: false
      t.string :sector
      t.string :asset_type, null: false
      t.string :unit

      t.timestamps
    end

    add_index :assets, :ticker, unique: true
  end
end
```

### Database Commands

```bash
# Create databases
bin/rails db:create

# Run pending migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (drop + create + migrate + seed)
bin/rails db:reset

# Seed data
bin/rails db:seed
```

---

## Background Jobs

### Framework: Solid Queue

Jobs use Solid Queue (database-backed, built into Rails 8).

### Job Template

```ruby
class MyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # job logic here
    Rails.logger.info("MyJob completed")
  end
end
```

### Existing Jobs

| Job | Trigger | What it does |
|-----|---------|-------------|
| `FetchQuotesJob` | Cron: weekdays 10:00, 14:00, 18:00 | `QuoteFetcher.new.fetch_all` |
| `GenerateReportsJob` | Cron: weekdays 18:30 | Exports CSV, JSON, MD, AI reports |

### Recurring Schedule (`config/recurring.yml`)

```yaml
production:
  fetch_quotes:
    class: FetchQuotesJob
    queue: default
    schedule: "0 10,14,18 * * 1-5"    # Weekdays at 10, 14, 18

  generate_reports:
    class: GenerateReportsJob
    queue: default
    schedule: "30 18 * * 1-5"          # Weekdays at 18:30

  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
```

### Adding a New Recurring Job

1. Create job in `app/jobs/my_job.rb`
2. Add schedule entry in `config/recurring.yml` under the `production` key
3. Add test in `test/jobs/my_job_test.rb`

---

## API Design

### Current API Endpoints

| Method | Path | Controller | Description |
|--------|------|-----------|-------------|
| GET | `/api/quotes` | `Api::QuotesController#index` | All quotes (filter: `?date=`) |
| GET | `/api/signals` | `Api::SignalsController#index` | Active trading signals |
| GET | `/api/scoring` | `Api::ScoringController#index` | Watchlist scoring |

### API Response Format

All API responses use JSON with consistent structure:

```json
{
  "total": 128,
  "quotes": [
    {
      "ticker": "PETR4.SA",
      "nome": "Petrobras",
      "setor": "Petróleo e Gás",
      "tipo": "stock",
      "preco_brl": 42.50
    }
  ]
}
```

### Adding New API Endpoints

1. Create controller in `app/controllers/api/`:
```ruby
module Api
  class NewController < BaseController
    def index
      # delegates to service
      data = SomeService.process(params)
      render_json(data)
    end
  end
end
```

2. Add route in `config/routes.rb`:
```ruby
namespace :api do
  resources :quotes, only: [:index]
  get "signals", to: "signals#index"
  get "new_endpoint", to: "new#index"    # Add here
end
```

3. Add test in `test/controllers/api/new_controller_test.rb`

---

## Data Flow & Architecture

### Request Flow

```
Browser → Puma → Rails Router → Controller → Service → ActiveRecord → PostgreSQL
                                    ↓
                              View (ERB + Tailwind)
                                    ↓
                              Turbo/Stimulus (client-side)
```

### Background Job Flow

```
Solid Queue Scheduler
    ↓ (cron trigger)
FetchQuotesJob
    ↓
QuoteFetcher.fetch_all
    ↓
YahooFinanceClient → Yahoo Finance API
NewsFetcher → Google News RSS
PolymarketClient → Polymarket API
SignalDetector → signal classification
    ↓
Quote.create! (database)
```

### Key Design Patterns

| Pattern | Where Used | Description |
|---------|-----------|-------------|
| Service Object | `app/services/` | Business logic isolated from controllers |
| Struct/Value Object | `SignalDetector::Result` | Immutable result objects |
| Static Catalog | `AssetCatalog` | Configuration as code (frozen hashes) |
| Orchestrator | `QuoteFetcher` | Coordinates multiple services |
| Transformer | `ExporterService.format_row` | Converts DB records to export format |
| Adapter | `YahooFinanceClient` | Wraps external API with retry/backoff |

---

## Export & Reporting

### Export Formats

| Format | File Pattern | Description |
|--------|-------------|-------------|
| CSV | `exports/cotacoes_YYYY-MM-DD.csv` | Tabular data with Portuguese headers |
| JSON | `exports/cotacoes_YYYY-MM-DD.json` | Structured data with metadata |
| Report | `exports/report_YYYY-MM-DD.md` | Human-readable Markdown summary |
| AI Report | `exports/ai_report_YYYY-MM-DD.json` | AI-structured JSON with insights |

### Export Service Usage

```ruby
# From controller or job
ExporterService.export_csv
ExporterService.export_json
ExporterService.export_report
ExporterService.export_ai_report

# Helper methods used by controllers
quotes = ExporterService.latest_quotes(quote_date: Date.today)
row = ExporterService.format_row(quote)
```

---

## Authentication

### Flow

1. User visits `/login` → sees Google OAuth button
2. Clicks button → redirected to Google OAuth consent
3. Google redirects back to `/auth/google_oauth2/callback`
4. `SessionsController#create` finds/creates user via `User.from_omniauth`
5. Session stores `user_id` → user is logged in
6. `ApplicationController#require_login` checks `session[:user_id]` on every request

### OmniAuth Configuration

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
    prompt: "select_account",
    image_aspect_ratio: "square",
    image_size: 50
  }
end
OmniAuth.config.allowed_request_methods = %i[get post]
```

### Testing Auth

```ruby
# In integration tests
login_as(users(:alice))
get protected_path
assert_response :success

# Testing auth redirect
get protected_path
assert_redirected_to login_path
```

---

## Deployment

### Docker (Development)

```bash
docker compose up          # Start PostgreSQL + Rails
docker compose build       # Rebuild after changes
docker compose exec web bin/rails console  # Console
```

### Kamal (Production)

Configuration in `config/deploy.yml`. Commands:

```bash
kamal setup     # First-time deploy
kamal deploy    # Subsequent deploys
kamal rollback  # Rollback to previous version
kamal app logs  # View logs
```

### Dockerfile

Multi-stage build:
1. **base** — Ruby slim image + PostgreSQL client
2. **build** — installs gems, precompiles assets/bootsnap
3. **final** — copies artifacts, creates non-root user, exposes port 80

---

## Validation Checklist

**Before committing or submitting any change, run ALL of these:**

```bash
# 1. Tests (must pass 100%)
bin/rails test

# 2. Linting (must have 0 offenses)
bundle exec rubocop

# 3. Security (must have 0 warnings)
bin/brakeman --no-pager

# 4. Type checking (must have 0 errors)
bundle exec srb tc
```

**When adding new features:**

- [ ] Service has `# frozen_string_literal: true` and `# typed: true`
- [ ] Service uses `extend T::Sig` with method signatures
- [ ] Controller is thin — logic delegated to service
- [ ] Test file created with meaningful test cases
- [ ] Fixtures updated if new models added
- [ ] Migration created if schema changes needed
- [ ] Route added in `config/routes.rb`
- [ ] `bin/tapioca dsl` run if new ActiveRecord models added
- [ ] All 4 validation commands pass

**When modifying existing code:**

- [ ] Existing tests still pass
- [ ] Sorbet signatures updated if method signatures changed
- [ ] No new RuboCop offenses introduced
- [ ] No new Brakeman warnings

---

*This guide reflects the codebase as of 2026-02-20. Update it when conventions change.*
