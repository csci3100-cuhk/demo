class AddStarsToMovie < ActiveRecord::Migration[7.1]
  def change
    change_table :movies do |t|
      t.integer :stars
    end
  end
end
