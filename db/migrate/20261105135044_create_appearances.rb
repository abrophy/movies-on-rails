class CreateAppearances < ActiveRecord::Migration[8.1]
  def change
    create_table :appearances do |t|
      t.references :movie, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: true
      t.references :filming_location, null: false, foreign_key: true

      t.timestamps
    end

    add_index :appearances, [ :movie_id, :actor_id, :filming_location_id ],
      unique: true,
      name: "index_appearances_on_movie_actor_location"
  end
end
