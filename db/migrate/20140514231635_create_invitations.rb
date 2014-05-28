class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.string :dance
      t.string :place
      t.string :message
      t.datetime :date
      t.string :status, default: 'pending'
      t.references :user, index: true
      t.references :partner, index: true

      t.timestamps
    end
  end
end
