---
description: Perform a strict pre-PR review of the current feature branch for the Dracma Rails project. Runs all automated gates and produces a section-by-section audit with a final GO or NO-GO verdict and a complete blockers list.
applyTo: "**"
---

# Pre-PR Review (Dracma)

You are performing a pre-PR review of the current feature branch.
Work through every section in order, gathering real evidence via tool calls.
Never skip a section. Never produce a verdict without executing the mandatory commands first.

---

## 1. Automated Validation Suite (MANDATORY FIRST)

Run:
```bash
bin/check
```

If `bin/check` is unavailable, run each individually and report exact output:
- `bin/rails test`
- `bundle exec rubocop`
- `bin/brakeman --no-pager`
- `bundle exec srb tc`

Record exact pass/fail for each. Any failure is an immediate blocker.
Do NOT skip or estimate this step. Missing evidence is itself a NO-GO.

---

## 2. Scope Inspection

Run:
```bash
git status --short
git diff --name-only HEAD~1
```

Identify: new services, controllers, models, jobs, mailers, routes, tests, config, docs.

---

## 3. Schema Awareness

For every changed method reading AR objects, verify against `db/schema.rb`:
- NOT NULL columns must not be nil-checked (`null: false` columns are never nil on persisted records)
- FK references must match real columns in `db/schema.rb`
- Integer signal flags (`signal_golden_cross`, etc.) must remain 0/1 — never boolean

---

## 4. Code Conventions

Audit changed files against project rules (`.github/copilot-instructions.md`, `CONTRIBUTING.md`):
- Thin controllers — delegate all logic to services
- Service files start with `# frozen_string_literal: true`
- Safe navigation for nullable values (`value&.round(2)`)
- Deterministic ordering: `.sort_by { ... }` MUST precede any `.first(N)` or `.last(N)` on DB-backed arrays
- Strict numeric parsing for user params (`Float(params[:x]) rescue nil` — never `.to_f`)
- No `relation.size` + subsequent `.map` (double query) — materialize with `.to_a` first
- No `Pathname.new(Rails.root.join(...))` — use `.to_s` or pass a String
- API responses: consistent key convention within one endpoint (no Portuguese/English mix)
- API route resources always include `only:` keyword

---

## 5. Security Audit

Check:
- No raw SQL string interpolation
- No unsanitized `params` in shell, `system()`, or file path construction
- No secrets/tokens/keys in source code
- Write API endpoints under `Api::` namespace (session-auth + CSRF disabled) — flag as blocker
- CSP nonce uses `SecureRandom.base64(16)`, not `session.id`
- Host allowlist regex anchored with `\A` and `\z`
- Rack::Attack inserted exactly once (not in both `config/application.rb` and initializer)
- Localhost safelist gated to `development?` or `test?` only

Confirm Brakeman result from step 1.

---

## 6. Test Coverage

- New public behavior must have a test file
- New API controllers must have an unauthenticated redirect test (`reset!` → request → `assert_response :redirect`)
- No `remove_method` / `undef_method` in test setup (permanently breaks later tests)
- No `sleep` or wall-clock assertions — use `travel_to`
- Prefer fixtures over inline `create!`
- Specific assertions only: `assert_equal`, `assert_predicate`, `assert_in_delta`, etc. — no bare `assert`
- Deterministic query before any `.first(N)` assertion

---

## 7. Routes, Docs, Tooling, Git Hygiene

- New routes follow naming conventions; API routes inside `namespace :api`
- No wildcard/catch-all routes
- ROADMAP.md updated if a roadmap item was completed
- README.md updated for significant features
- `.github/copilot-instructions.md` updated if new patterns were introduced
- No `puts`, `p`, `binding.pry`, `byebug`, `pp` left in changed files
- No unrelated files staged

---

## Decision Logic

**NO-GO** if ANY of the following are true:
- `bin/check` failed or evidence is missing
- A NOT NULL column is nil-checked
- A new endpoint lacks authentication
- A write API endpoint is CSRF-vulnerable
- CSP nonce uses `session.id`
- API controller test missing unauthenticated redirect test
- `remove_method` / `undef_method` in test setup
- Raw SQL injection vector present
- Rack::Attack inserted more than once
- Metric name/unit contract is misleading
- Tests missing for new public-facing behaviour

**GO** if all checks pass and no blockers remain. List any non-blocking suggestions separately.

---

## Output Format

Report findings grouped by section number.
At the end produce:

```
## Verdict: GO / NO-GO

### Blockers
- [description] — [file](path/to/file#Lnn)

### Suggestions (non-blocking)
- ...
```
