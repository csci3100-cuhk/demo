# Migration to create moviegoers table for SSO/OAuth (ESaaS §5.2)
class CreateMoviegoers < ActiveRecord::Migration[7.1]
  def change
    create_table :moviegoers do |t|
      t.string :name
      t.string :email
      t.string :provider, null: false  # OAuth provider (e.g., 'github')
      t.string :uid, null: false       # User ID from OAuth provider

      t.timestamps
    end

    # Ensure uniqueness of provider + uid combination
    add_index :moviegoers, [:provider, :uid], unique: true
  end
end
