---
mode: agent
description: Full pre-PR review — runs all validation checks and audits code quality, security, tests, and project conventions before opening a pull request.
tools:
  - run_in_terminal
  - read_file
  - grep_search
  - file_search
  - get_errors
---

You are performing a pre-PR review of the current feature branch for the **Dracma** Rails project. Work through every section below in order. Report findings grouped by section. At the end, give a clear **GO / NO-GO** verdict with a list of any blockers.

---

## 1. Automated Validation Suite

Run the full check suite and report the result:

```bash
bin/check
```

All four checks must pass with zero failures, zero offenses, and zero warnings:
- `bin/rails test` — 100% tests passing
- `bundle exec rubocop` — 0 offenses
- `bin/brakeman --no-pager` — 0 warnings
- `bundle exec srb tc` — 0 Sorbet type errors

If `bin/check` is unavailable, run each command individually.

---

## 2. Schema Awareness Check

For every new or modified method that reads from ActiveRecord objects, verify the following against `db/schema.rb`:

- **Don't nil-check NOT NULL columns.** `null: false` columns can never be nil on a persisted record. Use value-level checks instead:
  - Bad: `quote.price_brl.nil?`
  - Good: `quote.price_brl.to_f <= 0.0`
- **Don't presence-validate NOT NULL columns at the app layer** unless you specifically want an app-level error message.
- **Foreign keys** — confirm any new FK references match a real column in `db/schema.rb`.
- **Integer signal columns** — signal flags (`signal_golden_cross`, etc.) are stored as integers 0/1, not booleans.

---

## 3. Code Conventions (from CONTRIBUTING.md)

### Service files
- [ ] Every file in `app/services/` starts with `# frozen_string_literal: true`
- [ ] Module services use `def self.method` (no instances); class services use `initialize`
- [ ] Safe navigation used for nullable values: `value&.round(2)`, `headline&.slice(0, 500)`
- [ ] External API calls rescue `StandardError => e` and return a safe default (`[]` or `{}`)
- [ ] Constants are frozen: `KEYWORDS = { ... }.freeze`

### Controllers
- [ ] Controllers contain no business logic — delegate everything to services
- [ ] API controllers inherit from `Api::BaseController` and use `render_json` / `render_error`
- [ ] Resource loading uses `before_action :set_resource, only: [...]`
- [ ] API `resources` declarations always include `only:` — omitting it generates `new`/`edit` routes that have no action and will raise `ActionNotFound` at runtime:
  - Bad: `resources :portfolios`
  - Good: `resources :portfolios, only: %i[index show create update destroy]`

### Models
- [ ] Models contain only associations, validations, enums, and simple class methods
- [ ] Enums use integer backing with prefix: `enum :type, { buy: 1 }, prefix: true`

### Time/duration math
- [ ] Use `.to_f` (not `.to_i`) when passing a variable into `.hours`, `.minutes`, `.seconds`, or any fractional duration. `.to_i` silently truncates.

### User input parsing
- [ ] Never use `.to_f` or `.to_i` to parse user-supplied numeric params — both silently convert invalid strings to `0.0`/`0` and persist garbage data. Use strict parsing with a rescue:
  ```ruby
  value = Float(params[:price]) rescue nil
  return render_error("Invalid price", status: :bad_request) if value.nil?
  ```

### Sampling / ordering
- [ ] Any `.first(N)` or `.last(N)` on an array produced from a DB query must be preceded by an explicit `.sort_by { ... }` to guarantee deterministic ordering in tests and UIs.

### ActiveRecord query efficiency
- [ ] Never call `.size` on an AR Relation and then `.map`/`.each` on it — `.size` fires a `COUNT(*)` query, then the enumeration fires a second query. Materialize once with `.to_a` and use `.length`:
  - Bad: `render_json({ total: relation.size, items: relation.map { ... } })`
  - Good: `records = relation.to_a; render_json({ total: records.length, items: records.map { ... } })`
- [ ] Avoid calling `.count` on associations inside a loop — this is an N+1. Preload with `includes` or use a single grouped query.
- [ ] Prefer a single `OR` query over multiple sequential lookups for the same record:
  - Bad: `Asset.find_by(id: v) || Asset.find_by(ticker: v) || Asset.find_by(ticker: "#{v}.SA")`
  - Good: `Asset.where(id: v).or(Asset.where(ticker: [v, "#{v}.SA"])).first`

### API response key consistency
- [ ] API responses must use consistent key naming — never mix Portuguese keys (`preco_brl`, `setor`) from `ExporterService.format_row` with English keys (`price_brl`, `sector`) from other helpers in the same JSON object. Pick one convention per endpoint and translate if needed.

### Pathname safety
- [ ] Never pass a `Pathname` object into `Pathname.new(...)` — it raises `TypeError`. Call `.to_s` first:
  - Bad: `Pathname.new(Rails.root.join("exports"))`
  - Good: `Pathname.new(Rails.root.join("exports").to_s)` or just `Rails.root.join("exports")`

---

## 4. Test Coverage

- [ ] New services have a corresponding test file in `test/services/`
- [ ] New API controllers have a test in `test/controllers/api/`
- [ ] Tests cover at least: happy path, missing/edge-case input, authentication requirement
- [ ] **Every API controller test file includes an unauthenticated request test** — `reset!` followed by the request → `assert_response :redirect`. This must never be omitted, even if behaviour seems obvious.
- [ ] No bare `assert` — use specific assertions: `assert_equal`, `assert_predicate`, `assert_in_delta`, `assert_operator`, `assert_includes`
- [ ] No `sleep` or time-sensitive assertions — use `travel_to` from ActiveSupport if needed
- [ ] Fixtures rather than inline `create!` calls where possible; `create!` only for test-specific variations
- [ ] Tests that assert sample/subset inclusion use a deterministic query (sorted before truncation)
- [ ] **Never use `remove_method` or `undef_method` in test setup** — it permanently removes the method for the entire test process and breaks any later test that uses it. Use `stub` on the filesystem/dependency, inject a temp path, or refactor the subject to accept parameters.
- [ ] If SimpleCov is enabled alongside parallel test execution, confirm `SimpleCov.use_merging true` is set so coverage data is merged across processes.

---

## 5. Security (OWASP + Brakeman)

- [ ] No raw SQL interpolation — use parameterized queries (`where("col = ?", val)`)
- [ ] No `params` values used unsanitized in shell commands, file paths, or `system()` calls
- [ ] No secrets, tokens, API keys, or credentials in source code
- [ ] Brakeman passes with 0 warnings (`bin/brakeman --no-pager`)

### CSRF on session-authenticated API endpoints
- [ ] `Api::BaseController` skips CSRF token verification (`skip_before_action :verify_authenticity_token`). This is safe for read-only (`GET`) endpoints, but **POST/PATCH/DELETE endpoints backed by session cookies are CSRF-vulnerable**. For any write endpoint added under `Api::`, either:
  - Re-enable CSRF protection for that action, or
  - Switch to token-based auth (e.g. `Authorization: Bearer`) and keep CSRF disabled only for true non-browser consumers.

### Content Security Policy
- [ ] CSP nonces must use `SecureRandom.base64(16)` — never `request.session.id`. Session IDs are long-lived and predictable, which defeats the nonce's purpose:
  - Bad: `config.content_security_policy_nonce_generator = ->(_req) { request.session.id.to_s }`
  - Good: `config.content_security_policy_nonce_generator = ->(_req) { SecureRandom.base64(16) }`
- [ ] Do not include `:unsafe_inline` in `style-src` or `script-src` — use nonces or hashes instead.

### Host allowlist regex
- [ ] Subdomain regexes for `config.hosts` must use `\A` and `\z` anchors to prevent partial matches from allowing malicious hostnames:
  - Bad: `/.*\.#{Regexp.escape(host)}/`
  - Good: `/\A[a-z0-9-]+\.#{Regexp.escape(host)}\z/i`

### Rack::Attack middleware
- [ ] Rack::Attack must be inserted into the middleware stack exactly once — either in `config/application.rb` OR in `config/initializers/rack_attack.rb`, never both. Inserting it twice halves effective rate limits.
- [ ] The localhost safelist must be gated to non-production environments — leaving it unconditional weakens rate limiting in production:
  ```ruby
  if Rails.env.development? || Rails.env.test?
    safelist("allow-localhost") { |req| req.ip == "127.0.0.1" || req.ip == "::1" }
  end
  ```

---

## 6. Routes

- [ ] New routes follow existing naming conventions in `config/routes.rb`
- [ ] API routes are inside `namespace :api do ... end`
- [ ] No catch-all routes or wildcard routes that could expose unintended actions

---

## 7. Documentation Drift

- [ ] If new service patterns or conventions were introduced, update `.github/copilot-instructions.md`
- [ ] If significant new features were added, update `README.md` Current Status section and the API routes table
- [ ] If a roadmap item was completed or started, update `ROADMAP.md`

---

## 8. CI / Dev Tooling

- [ ] If `lefthook.yml` was modified, confirm the RuboCop pre-commit hook uses `glob: "**/*.rb"` (recursive) — the bare `glob: "*.rb"` only matches the repo root and silently skips all staged files under `app/`, `config/`, `test/`, etc.
- [ ] If the Sorbet CI job was modified, confirm it fails on a non-zero `srb tc` exit code — filtering output and swallowing the exit code causes CI to pass while `bin/check` fails locally.

## 9. Git Hygiene

- [ ] Branch name follows convention: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`
- [ ] Commit messages follow: `type(scope): short description` (e.g. `feat(api): add health endpoint`)
- [ ] No debug output (`puts`, `p`, `binding.pry`, `byebug`, `pp`) left in changed files
- [ ] No unrelated files staged or committed

---

## Verdict

After completing all sections, respond with:

**GO** — if all checks pass and no blockers found. List any non-blocking observations as suggestions.

**NO-GO** — if any of the following are true:
- `bin/check` fails for any reason
- A NOT NULL column is nil-checked
- A new endpoint lacks authentication
- A write API endpoint is CSRF-vulnerable (session auth + `skip_before_action :verify_authenticity_token`)
- A CSP nonce uses `session.id` instead of `SecureRandom`
- An API controller test file is missing the unauthenticated request test
- `remove_method`/`undef_method` is used in test setup
- A raw SQL injection vector is present
- Rack::Attack is registered more than once in the middleware stack
- Tests are missing for new public-facing behaviour

List every blocker with the file and line number.
