# Migration to create reviews table with foreign keys (ESaaS §5.4)
# Reviews implement many-to-many relationship between movies and moviegoers
class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.integer :potatoes, null: false  # Rating 1-5 "potatoes"

      # Foreign keys using references (ESaaS §5.4)
      # Rails infers the model from the column name
      # References automatically turns 'movie' into 'movie_id' in the DB
      t.references :movie, null: false, foreign_key: true
      t.references :moviegoer, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure a moviegoer can only review a movie once
    add_index :reviews, [:movie_id, :moviegoer_id], unique: true
  end
end
