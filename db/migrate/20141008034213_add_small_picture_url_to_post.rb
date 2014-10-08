class AddSmallPictureUrlToPost < ActiveRecord::Migration
  def change
    add_column :posts, :small_picture_url, :text
  end
end
