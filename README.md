# Movies on rails

This is the solution to a take home assessment as provided.

Primarily this is a Ruby on Rails application that will provide

# Tech used

Rails 8
Hotwire and turbo for frontend (no need for extensive frontend framework yet)

# Installation

# Implemented features

# Planned features

- data import (movies.csv, reviews,csv)
- movies overview of all movies as landing page, sorted by star rating (reviews)
- specific movie overview
- specific actor overview
- actor search

# Notes on implementation

One interesting decision I had to make here is how to model the Movies x Actors x Locations links. In the csv's provided every actor linked to a movie was present at every location. However this might not necessarily be true in the wild.

We could set up simpler relationships where a movie has multiple locations, and then we can figure out what locations the actors worked at through that link. However if there ever is an instance where an actor did not work on one of the distinct movie locations. We would lose this data on an import because it's not supported by the schema.

At the scale of this take home the minimization of table rows and efficiency gains here are negligible. So I think it's worth future proofing a bit. If anything else it's an interesting discussion point to bring up at review time.
