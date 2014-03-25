class AddDancesToUser < ActiveRecord::Migration
  def change
    add_column :users, :dances, :text, array: true, default: []
  end
end
