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
bin/rails db:prepare
bin/rails data:import      # loads movies.csv and reviews.csv (idempotent)
bin/dev                    # http://localhost:3000 (server + Tailwind watcher)
```

`bin/rails tailwindcss:build` compiles the CSS once if you prefer `bin/rails server` over `bin/dev`.

## Tests

```bash
bin/rails test
```

## Implemented features

- **CSV importer** (`bin/rails data:import`) that is idempotent and aware of the
  denormalized shape of `movies.csv`
- **Landing page** — all movies, sorted by average star rating; movies with no
  reviews sort last
- **Movie overview page** — description, director, year, cast, filming locations,
  and reviews with rating
- **Actor overview page** — the actor's movies and filming locations
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

| Method | Path | Description |
| ------ | ---- | ----------- |
| GET | `/api/v1/movies` | Movies sorted by average rating (includes `average_rating` and `review_count`) |
| GET | `/api/v1/movies/:id` | One movie with its actors, locations, and reviews |
| GET | `/api/v1/actors` | All actors |
| GET | `/api/v1/actors?q=...` | Search actors by name (case-insensitive substring) |
| GET | `/api/v1/actors/:id` | One actor with their movies and filming locations |

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
`movies.csv` is a full cartesian product of each movie's actors and locations.

The simpler alternative is to model a movie as having many locations and deriving
an actor's locations through that link. But that schema cannot represent a case
where an actor did *not* film at one of a movie's distinct locations — the data
would be silently lost on import.

At the scale of this take-home, the row-count and efficiency difference is
negligible, so I model the `(movie, actor, location)` triple explicitly in the
`appearances` table. This is faithful to the source data and future-proofs against
partial actor–location sets.

### Idempotent importer

The importer deduplicates entities in memory, then bulk-inserts with
`insert_all(..., unique_by:)` against unique indexes, so re-running it is a no-op
rather than producing duplicates.

### No authentication

The brief mentions security, not authentication, and every endpoint is read-only.
Security is handled with Rails defaults: strong parameters, CSRF protection,
parameterized queries, and escaping of `LIKE` wildcards in search.

### Other decisions

- Reviews reference movies by title, so `movies.title` is unique and indexed.
- A reviewer can only review a movie once (`[movie_id, reviewer]` is unique).
- Movies with no reviews sort last with an effective rating of 0.
