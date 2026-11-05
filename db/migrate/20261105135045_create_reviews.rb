class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :movie, null: false, foreign_key: true
      t.string :reviewer, null: false
      t.integer :stars, null: false
      t.text :body

      t.timestamps
    end

    add_index :reviews, [ :movie_id, :reviewer ], unique: true, name: "index_reviews_on_movie_and_reviewer"
    add_check_constraint :reviews, "stars >= 1 AND stars <= 5", name: "stars_between_1_and_5"
  end
end
