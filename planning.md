# High level project structure

rails 8 using turbo links for rendering pages
will work with sqlite (default db provider) at first but I need to think of whether I'll set up some orchestrated containers for this solution.
Security, will I require auth? The task doesn't request for it specifically, it just mentions security.
Input fields (if managed correctly) will be sanitized by default I'll just need to be careful of that.
Will add a security best practice pass to the todos

# Brainstorm

So the challenge here is that we need to set up an efficient importer. Theres a deceptive chain of related potential models hidden in just the two import csvs:

movies.csv - columns:
Movie,Description,Year,Director,Actor,Filming location,Country

reviews.csv - columns:
Movie,User,Stars,Review

in movies.csv there can be multiple entries for a single movie. Director and title (Director, Movie columns respectively) will be consistent. But there can be multiple unique actors ( we will need to set up actor models and views for each) and these actors can also have been present at multiple shooting locations, and each location has a country, therefore having multiple entries for themselves.

We need to set up the DB schema to represent this and make it efficiently render/search.
Also making the importer is going to be tricky. I don't want to have to search for a movie for every single line in the movies.csv

While importing the CSV's, rather than search for an existing model one by one and therefore slowing it down with a ton of db queries. We'll do batch processing that loads the CSV data into hashes that we can then use to populate the database as necessary.
I'll orient this process around the movies because that's the core object linking everything else.

Possible relationship tree:

Movie -> has_many -> reviews
Movie -> linking_table -> appearances
Actor -> linking_table -> appearances
Location -> linking_table -> appearances

The fields these models will have:

Actor {
string: name
}

Movie {
string: title
text: description
integer: year
string: director (anticipate this might need a model/search in the future but OOS)
}

FilmingLocation {
string: name
string: country
}

Appearances (rich linking table) {
movie_id: int
actor_id: int
filming_location_id: int
}

# Planned steps:

- [] create db structure with models/relations
- [] create indices for tables as necessary
- [] create CSV import tasks. These should use batch processing, first loading the CSV data into memory before reaching out to the DB to check for existing records.
- [] add a front-end css framework provide some basic components
- [] list page for all movies, sorted by average stars, as landing page
- [] overview page for specific movie
- [] overview page for specific actor
  include a list of all the movies they're in, showing the locations they filmed at there (can use appearances)
- [] search form that allows to search for an actor
- [] expose the data through a well designed set of api endpoints
  movie list
  specific movie
  specific actor
  actor search
- [] Docker compose?
- [] TDD Completeness pass
- [] DRY pass
- [] SOLID principle pass

# Decisions to be made before committing

- How to handle movies without reviews - Due to having limited data at the moment I'll have them still in the returned results but at the bottom of the ordering. Will need to display unknown rating somehow.
  One thing I might highlight at discussion time/review is that theres a chance that a movie with a single review can beat the most popular movie with a ton of reviews. Should we consider this or protect against it, weighting movie results based on number of reviews? Definitely out of scope for this challenge but an interesting discussion point.

- auth - is this necessary?
