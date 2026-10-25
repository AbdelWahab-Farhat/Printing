# Printing-Bags

## Commit messages

Every commit message is in **English**: short, simple to understand and clean. This holds even
though code comments, docs and chat are in Arabic.

Format ([Conventional Commits](https://www.conventionalcommits.org)):

```
type(scope): short summary

Optional body: what changed and why, in plain sentences.
Wrap lines at 72 characters.
```

- **type**: `feat` · `fix` · `refactor` · `perf` · `test` · `docs` · `chore` · `build` · `ci` · `revert`
- **scope**: the feature or area, in kebab-case: `orders`, `internal-tickets`, `investment-fund`,
  `treasury`, `scripts`, `release` …
- **summary**: imperative mood ("add", not "added"), lower case after the colon, no full stop,
  72 characters at most.
- **No Arabic** anywhere in the message. Name a UI label by its English meaning ("Paid", not «المدفوع»).
- One logical change per commit. The server and app halves of a feature may be separate commits.
- No `git add -A`. Name the files, because several sessions share this working tree.

Examples:

```
feat(orders): show the overpaid amount next to "Paid"
fix(orders): send booleans as 1/0 in multipart requests
chore(release): staff 1.13.0 (12)
```
