# Planning & decisions

This file records the key decisions made while building the app. The up-to-date
feature/usage documentation lives in [README.md](README.md).

## Stack

- Rails 8.1, Ruby 3.4
- SQLite
- Hotwire / Turbo (no JS framework), minimal CSS

## Schema decision

`movies.csv` is denormalized — one row per `(movie, actor, filming location)`, and
the data is a full cartesian product of each movie's actors × locations.

Chosen model: an explicit `appearances` join table carrying
`(movie_id, actor_id, filming_location_id)`, rather than two independent joins
(`movie ↔ actor` and `movie ↔ location`). This is faithful to the source and can
represent partial actor–location sets in larger real-world data, which the simpler
two-join model cannot. Actor locations are derived through `appearances` with
`DISTINCT`.

## Importer

Idempotent by construction: dedupe in memory, then `insert_all(..., unique_by:)`
against unique indexes. Re-running produces identical counts.

## Resolved open questions

- **Auth** — skipped. The brief mentions security, not authentication; every
  endpoint is read-only. Security relies on Rails defaults (strong params, CSRF,
  parameterized queries, LIKE-escaping).
- **Docker / HTTPS** — out of scope for a SQLite take-home.

## Done

- [x] DB structure with models, relations, and indexes
- [x] Idempotent CSV import task
- [x] Landing page: all movies sorted by average rating (zero-review movies last)
- [x] Movie overview page
- [x] Actor overview page
- [x] Actor search
- [x] JSON API (movie list, movie, actor, actor search)
- [x] Test suite (models, importer idempotency, HTML + API integration)
