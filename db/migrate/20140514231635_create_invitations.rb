class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.string :place
      t.string :message
      t.datetime :date
      t.boolean :status, default: false
      t.references :user, index: true
      t.references :partner, index: true

      t.timestamps
    end
  end
end
