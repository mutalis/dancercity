class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :entry_id
      t.text :caption
      t.datetime :published_at
      t.text :description
      t.string :link
      t.text :message      
      t.string :link_name
      t.string :picture_url
      t.string :video_url
      t.string :status_type_desc
      t.string :status_type

      t.string :slug
      t.boolean :is_published, default: false
      t.string :fb_permalink
      t.references :user, index: true

      t.timestamps
    end
    add_index :posts, :slug, unique: true
  end
end
