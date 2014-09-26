class AddFbObjectIdIndexToPost < ActiveRecord::Migration
  def change
    add_index :posts, :entry_id
  end
end
