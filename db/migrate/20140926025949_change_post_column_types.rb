class ChangePostColumnTypes < ActiveRecord::Migration
  def change
    change_column :posts, :link, :text
    change_column :posts, :link_name, :text
    change_column :posts, :picture_url, :text
    change_column :posts, :video_url, :text
  end
end
