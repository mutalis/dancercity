class AddMediumPictureUrlToPost < ActiveRecord::Migration
  def change
    add_column :posts, :medium_picture_url, :text
  end
end
