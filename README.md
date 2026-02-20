# Dracma

Brazilian stock market (B3) tracker and portfolio manager built with Ruby on Rails 8. Monitors quotes, detects trading signals, scores watchlists, and manages portfolios — all with a modern Hotwire-powered UI.

Migrated from a Python/FastAPI application ([b3_tracker](../b3_tracker)).

## Features

- **Quote Fetching** — Real-time quotes from Yahoo Finance for B3 and US stocks
- **Signal Detection** — Automatic buy/sell signal detection based on technical indicators
- **Watchlist Scoring** — AI-powered scoring of watch-listed tickers with sentiment analysis
- **Portfolio Management** — Track positions, transactions, and portfolio performance
- **News Sentiment** — Google News RSS feed sentiment analysis (English & Portuguese)
- **Polymarket Integration** — Prediction market sentiment data
- **Exports** — CSV, JSON, and AI-readable report generation
- **Scheduled Jobs** — Background quote fetching and report generation via Solid Queue
- **Google OAuth** — Multi-user authentication via OmniAuth

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Rails 8.0 |
| Ruby | 3.3+ |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Background Jobs | Solid Queue |
| Asset Pipeline | Propshaft + Importmap |
| Auth | OmniAuth (Google OAuth2) |
| Type Checking | Sorbet (`# typed: true`) |
| Linting | RuboCop (Rails Omakase + Minitest) |
| Testing | Minitest + WebMock |
| Deployment | Kamal (Docker) |

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
cp .env.example .env  # or export manually:
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

## Running Tests

```bash
# Full test suite
bin/rails test

# Specific test file
bin/rails test test/services/quote_fetcher_test.rb

# With verbose output
bin/rails test -v
```

## Linting

```bash
# Check for offenses
bundle exec rubocop

# Auto-fix correctable offenses
bundle exec rubocop -A
```

## Architecture

```
app/
├── controllers/       # Rails controllers + API namespace
├── javascript/
│   └── controllers/   # Stimulus controllers (flash, auto_refresh, confirm, sortable)
├── jobs/              # Solid Queue jobs (fetch_quotes, generate_reports)
├── models/            # ActiveRecord models (User, Asset, Quote, Portfolio, etc.)
├── services/          # Business logic (Sorbet-typed)
│   ├── asset_catalog.rb        # B3 + US stock catalog
│   ├── exporter_service.rb     # CSV/JSON/report exports
│   ├── news_fetcher.rb         # Google News RSS sentiment
│   ├── polymarket_client.rb    # Prediction market data
│   ├── portfolio_service.rb    # Portfolio CRUD & performance
│   ├── quote_fetcher.rb        # Yahoo Finance quote fetcher
│   ├── sentiment_analyzer.rb   # Text sentiment scoring
│   ├── signal_detector.rb      # Buy/sell signal detection
│   ├── watchlist_scorer.rb     # Watchlist ranking & scoring
│   └── yahoo_finance_client.rb # Yahoo Finance API client
└── views/             # ERB templates with Tailwind CSS

config/
├── routes.rb          # RESTful routes + API namespace
└── initializers/
    └── omniauth.rb    # Google OAuth2 configuration
```

## Routes

| Path | Description |
|------|-------------|
| `/` | Dashboard with market overview |
| `/instruments` | Asset catalog (B3 + US stocks) |
| `/quotes` | Daily quotes with sortable table |
| `/watchlists` | Watchlist with scoring |
| `/portfolios` | Portfolio management |
| `/portfolios/:id/positions` | Portfolio positions |
| `/exports` | CSV/JSON/report exports |
| `/api/quotes` | JSON API for quotes |
| `/api/signals` | JSON API for signals |
| `/api/scoring` | JSON API for scoring |

## Docker

```bash
# Development
docker compose up

# Production
docker compose -f docker-compose.prod.yml up
```

## License

Private project.
