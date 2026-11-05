class CreateMovies < ActiveRecord::Migration[8.1]
  def change
    create_table :movies do |t|
      t.string :title, null: false
      t.text :description
      t.integer :year
      t.string :director

      t.timestamps
    end

    add_index :movies, :title, unique: true
    add_index :movies, :director
  end
end
