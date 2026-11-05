# Movies on Rails

A Ruby on Rails take-home assessment: import two flat CSVs, normalize them into a
relational schema, and expose the data through web pages and a small JSON API.

## Tech used

- **Ruby 3.4**, **Rails 8.1**
- **SQLite** (Rails default — no external database needed)
- **Hotwire / Turbo** for the frontend, **Tailwind CSS** for styling — no JS framework

## Installation

```bash
bundle install
bin/rails db:prepare      # creates DB, migrates, and seeds the CSVs
bin/dev                    # http://localhost:3000 (server + Tailwind watcher)
```

`db:prepare` seeds the CSVs on a fresh database (via `db/seeds.rb`). To re-import, use the import tasks:

```bash
bin/rails data:import          # both files, movies then reviews
bin/rails data:import_movies   # movies only
bin/rails data:import_reviews  # reviews only (movies must already exist)
```

Each task accepts a path override via an environment variable (absolute or Rails-root-relative):

```bash
MOVIES=/path/to/movies.csv  bin/rails data:import_movies
REVIEWS=/path/to/reviews.csv bin/rails data:import_reviews
```

`bin/rails tailwindcss:build` compiles the CSS once if you prefer `bin/rails server` over `bin/dev`.

## Tests

```bash
bin/rails test
```

## Linting

```bash
bundle exec rubocop
```

## Implemented features

- **CSV importer** (`bin/rails data:import`) that is idempotent and aware of the
  denormalized shape of `movies.csv`
- **Landing page** — all movies, sorted by average star rating; movies with no
  reviews sort last
- **Movie overview page** — description, director, year, cast, filming locations,
  and reviews with rating
- **Actor overview page** — the actor's movies and filming locations
- **Location overview page** — the movies filmed at a given location
- **Actor search** — case-insensitive substring search
- **JSON API** — the same data as machine-readable endpoints

## Data model

- `movies` — title (unique), description, year, director
- `actors` — name (unique)
- `filming_locations` — name + country (unique together)
- `appearances` — join of `movie × actor × filming_location` (unique together)
- `reviews` — movie, reviewer, stars (1–5), body

`Movie`, `Actor`, and `FilmingLocation` are each linked through `appearances`, so
an actor's filming locations can be derived across all the movies they appear in.

## API endpoints

| Method | Path                   | Description                                                                    |
| ------ | ---------------------- | ------------------------------------------------------------------------------ |
| GET    | `/api/v1/movies`       | Movies sorted by average rating (includes `average_rating` and `review_count`) |
| GET    | `/api/v1/movies/:id`   | One movie with its actors, locations, and reviews                              |
| GET    | `/api/v1/actors`       | All actors                                                                     |
| GET    | `/api/v1/actors?q=...` | Search actors by name (case-insensitive substring)                             |
| GET    | `/api/v1/actors/:id`   | One actor with their movies and filming locations                              |
| GET    | `/api/v1/locations/:id` | One location with the movies filmed there |

Example — `GET /api/v1/movies`:

```json
[
  {
    "id": 1,
    "title": "Gone in 60 seconds",
    "year": 2000,
    "director": "Dominic Sena",
    "average_rating": 3.6,
    "review_count": 5
  },
  {
    "id": 2,
    "title": "Inception",
    "year": 2010,
    "director": "Christopher Nolan",
    "average_rating": 2.75,
    "review_count": 4
  }
]
```

## Notes on implementation

### Movies × actors × locations

One interesting decision was how to model the `Movies × Actors × Locations` links.
In the provided CSVs, every actor linked to a movie was present at every location —
`movies.csv`.

The simpler alternative is to model a movie as having many locations and deriving
an actor's locations through that link. But that schema cannot represent a case
where an actor did _not_ film at one of a movie's distinct locations; the data
would be silently lost on import.

At the scale of this take-home, the row-count and efficiency difference is
negligible, so I model the `(movie, actor, location)` triple explicitly in the
`appearances` table. This is faithful to the source data and future-proofs against
partial actor–location sets.

### Importer

Two importers — `MoviesImporter` and `ReviewsImporter` — treat the CSVs as
untrusted input:

- **Structure validation** — each file's header row must match the expected
  columns exactly; anything else raises an error before any data is written.
- **Sanitization** — values are trimmed and stripped of control characters, and
  `year`/`stars` are validated by type and range.
- **No SQL injection** — every write goes through `insert_all`, which binds values
  as SQL parameters; no CSV value is ever concatenated into SQL.
- **Fail loud, don't fail** — malformed rows are skipped and reported (file, line,
  reason), and every valid row still imports.
- **Idempotent** — entities are deduplicated in memory and bulk-inserted with
  `insert_all(..., unique_by:)` against unique indexes, so re-running is a no-op.

### Security

The brief mentions security rather than authentication, and every endpoint is
read-only, so no login flow is required. Security is handled as follows:

- **SQL injection** — all queries are parameterized; no CSV or user input is ever
  concatenated into SQL, and `insert_all` binds values.
- **Search** — the actor search uses a bound parameter plus `LIKE`-escaping, so
  wildcards and hostile strings are treated literally.
- **XSS** — templates use ERB auto-escaping; there is no `html_safe`/`raw` output.
- **CSRF / mass assignment** — Rails defaults are in place, though with no
  state-changing routes or write params there is no surface to exploit.
- **Secrets** — `config/master.key` is gitignored; only the encrypted
  `credentials.yml.enc` is committed.
- **Data integrity** — unique indexes, foreign keys, and a `stars` CHECK
  constraint are enforced at the database level.

### Location overview page

The location overview page wasn't part of the requested feature set. I added it
because, once filming locations were modeled and linked from the movie and actor
pages, giving each location its own page (listing the movies filmed there) felt
like a natural way to round out the UI.

### Other decisions

- Reviews reference movies by title, so `movies.title` is unique and indexed.
- A reviewer can only review a movie once (`[movie_id, reviewer]` is unique).
- Movies with no reviews sort last with an effective rating of 0.
