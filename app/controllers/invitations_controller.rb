class InvitationsController < ApplicationController
  before_action :check_user_settings
  before_action :set_invitation, only: [:update]

  # respond_to :js

  def index
    if current_user && (current_user.slug == params[:user_id])
      @invitations = current_user.pending_invitations
    else
      raise "Error: no possible to get the invitations for the current user."
    end
  end

  def show
    if current_user
      @invitation = Invitation.find(params[:id])
      @is_inviter = (@invitation.partner.slug == params[:user_id])
      @is_invitee = (@invitation.user.slug == params[:user_id])

      # Checks that the slug Url match with current user slug
      if (current_user.slug == params[:user_id])
        if @is_inviter || @is_invitee
          @comments = @invitation.comments.includes(:user)
        else
          render nothing: true, status: :unauthorized
        end
      else
        redirect_to root_path
      end
    else
      send_to_signin
    end
  end
  
  def create
    invited_user = User.friendly.find(params[:user_id])
    send_to_signin unless current_user

    if current_user && invited_user
      @invitation = current_user.sent_invitations.create!(user_id: invited_user.id, date: Time.now, message: params[:invitation][:message])
      # @invitation = current_user.sent_invitations.create!(invitation_params)
      # redirect_to :back, notice: "The invitation has been sent."
      ManagerMailer.new_invitation(invited_user.email, new_inv_message(@invitation)).deliver
      ManagerMailer.invitation_sent(current_user.email, sent_inv_message(@invitation)).deliver
      # send_facebook_message(invited_user, new_inv_message(@invitation))
      flash.now[:notice] = "The invitation to #{invited_user.first_name} has been sent."
    else
      raise "Create invitation error."
    end
  end

  def update
    if (current_user.slug == params[:user_id]) && (params[:ans] == 'accepted' || params[:ans] == 'rejected')

     if @invitation.update(status: params[:ans])
       ManagerMailer.response_to_invitation(@invitation.partner.email, response_inv_message(params[:ans])).deliver
       # send_facebook_message(@invitation.partner, response_inv_message(params[:ans]))
       flash.now[:notice] = "You've #{params[:ans]} the invitation from #{@invitation.partner.first_name} #{@invitation.partner.last_name} ."
     end
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_invitation
    if current_user
      @invitation = current_user.invitations.find(params[:id])
    else
      redirect_to signin_path
    end
  end
  
  def send_to_signin
    session[:stored_path] = request.path
    redirect_to signin_path
  end

  def send_facebook_message(receiver, message)
    
    receiver_chat_id   = "-#{receiver.uid}@chat.facebook.com"
    sender_chat_id   = "-#{receiver.uid}@chat.facebook.com"

    jabber_message   = Jabber::Message.new(receiver_chat_id, message)
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

  def new_inv_message(invitation)
    "Dancer City notification:\n\n
    You've got an invitation to dance from #{current_user.first_name} #{current_user.last_name}.\n\n
    Please see the details at: #{user_invitation_url(invitation.user, invitation)}"
  end

  def sent_inv_message(invitation)
    "Dancer City notification:\n\n
    You sent a message to #{invitation.user.first_name} #{invitation.user.last_name}.\n\n
    You can follow up this conversation at: #{user_invitation_url(invitation.partner, invitation)}"
  end

  def response_inv_message(answer)
    message = "Dancer City notification:\n\n #{current_user.first_name} #{current_user.last_name}"
    if answer == 'rejected'
      message += " has rejected your invitation to dance. You can try again in another time.\n"
    else
      message += " has accepted your invitation to dance.\n"
    end
  end
  
end
