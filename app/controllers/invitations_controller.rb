class InvitationsController < ApplicationController
  before_action :set_invitation, only: [:show, :update]

  respond_to :js

  def index
    if current_user && (current_user.slug == params[:user_id])
      @invitations = current_user.pending_invitations
    else
      raise "Error: no possible to get the invitations for the current user."
    end
  end

  def show
    render nothing: true, status: :unauthorized if current_user.slug != params[:user_id]
  end
  
  def create
    invited_user = User.find(params[:user_id])
    
    if current_user && invited_user
      @invitation = current_user.sent_invitations.create!(user_id: invited_user.id, date: Time.now)
      # @invitation = current_user.sent_invitations.create!(invitation_params)
      # redirect_to :back, notice: "The invitation has been sent."
      send_facebook_message(invited_user, @invitation)
      flash.now[:notice] = "The invitation to #{invited_user.first_name} has been sent."
    else
      raise "Create invitation error."
    end
  end

  def update
    if (current_user.slug == params[:user_id]) && (params[:ans] == 'accepted' || params[:ans] == 'rejected')

     if @invitation.update(status: params[:ans])
       flash.now[:notice] = "You've #{params[:ans]} the invitation from #{@invitation.partner.first_name} ."
     end
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_invitation
    @invitation = current_user.invitations.find(params[:id]) if current_user
  end

  def send_facebook_message(receiver, invitation)
    
    receiver_chat_id   = "-#{receiver.uid}@chat.facebook.com"
    sender_chat_id   = "-#{receiver.uid}@chat.facebook.com"

    jabber_message   = Jabber::Message.new(receiver_chat_id, facebook_message(invitation))
    jabber_message.subject = "Dancer City"
  
    client = Jabber::Client.new(Jabber::JID.new(sender_chat_id))
    client.connect
    client.auth_sasl(Jabber::SASL::XFacebookPlatform.new(client,
     ENV!['FACEBOOK_KEY'], receiver.oauth_token, ENV!['FACEBOOK_SECRET']), nil)
    client.send(jabber_message)
    client.close
  rescue RuntimeError
    raise FacebookChatAccessDenied, "No access to Facebook Chat"
  end

  def facebook_message(invitation)
    "Dancer City notification:\n
    You got an invitation from #{current_user.first_name} #{current_user.last_name} to dance.\n
    Please see the details at: #{user_invitation_url(invitation.user, invitation)}"
  end
  
end
