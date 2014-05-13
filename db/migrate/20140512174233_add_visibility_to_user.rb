class AddVisibilityToUser < ActiveRecord::Migration
  def change
    add_column :users, :visibility, :string
    add_index :users, :visibility
  end
end
