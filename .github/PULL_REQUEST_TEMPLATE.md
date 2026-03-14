## Description

Brief description of what this PR does.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update

## Related Issues

Closes #(issue number)

## Validation Checklist

All checks must pass before merging:

- [ ] `bin/rails test` — all tests pass
- [ ] `bundle exec rubocop` — 0 offenses
- [ ] `bin/brakeman --no-pager` — 0 warnings
- [ ] `bundle exec srb tc` — 0 errors

Or run all at once: `bin/check`

## Additional Checklist

- [ ] Service files have `# typed: true` and Sorbet signatures on all methods
- [ ] Controllers are thin — business logic is in services
- [ ] Tests added for new functionality (both happy path and edge cases)
- [ ] `.github/copilot-instructions.md` updated if patterns/conventions changed
- [ ] Migration created if schema changes are needed
- [ ] `bin/tapioca dsl` run if new ActiveRecord models added
