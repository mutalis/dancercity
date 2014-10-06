class AddObjectIdToPost < ActiveRecord::Migration
  def change
    add_column :posts, :fb_object_id, :string
  end
end
