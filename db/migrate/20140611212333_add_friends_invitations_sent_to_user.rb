class AddFriendsInvitationsSentToUser < ActiveRecord::Migration
  def change
    add_column :users, :friends_invitations_sent, :boolean, default: false
  end
end
