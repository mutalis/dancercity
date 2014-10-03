class AddObjectIdToPost < ActiveRecord::Migration
  def change
    add_column :posts, :object_id, :string
  end
end
