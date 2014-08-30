class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :entry_id
      t.string :url
      t.text :summary
      t.datetime :published_at
      t.string :slug
      t.references :user, index: true

      t.timestamps
    end
    add_index :posts, :slug, unique: true
  end
end
