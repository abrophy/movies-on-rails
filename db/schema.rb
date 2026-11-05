# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_05_135045) do
  create_table "actors", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_actors_on_name", unique: true
  end

  create_table "appearances", force: :cascade do |t|
    t.integer "movie_id", null: false
    t.integer "actor_id", null: false
    t.integer "filming_location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_appearances_on_actor_id"
    t.index ["filming_location_id"], name: "index_appearances_on_filming_location_id"
    t.index ["movie_id", "actor_id", "filming_location_id"], name: "index_appearances_on_movie_actor_location", unique: true
    t.index ["movie_id"], name: "index_appearances_on_movie_id"
  end

  create_table "filming_locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "country"], name: "index_filming_locations_on_name_and_country", unique: true
  end

  create_table "movies", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "year"
    t.string "director"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["director"], name: "index_movies_on_director"
    t.index ["title"], name: "index_movies_on_title", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "movie_id", null: false
    t.string "reviewer", null: false
    t.integer "stars", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id", "reviewer"], name: "index_reviews_on_movie_and_reviewer", unique: true
    t.index ["movie_id"], name: "index_reviews_on_movie_id"
    t.check_constraint "stars >= 1 AND stars <= 5", name: "stars_between_1_and_5"
  end

  add_foreign_key "appearances", "actors"
  add_foreign_key "appearances", "filming_locations"
  add_foreign_key "appearances", "movies"
  add_foreign_key "reviews", "movies"
end
