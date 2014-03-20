class AddCurrentLocationToUser < ActiveRecord::Migration
  def change
    add_column :users, :longitude, :decimal, precision: 9, scale: 6
    add_column :users, :latitude, :decimal, precision: 9, scale: 6
  end
end
