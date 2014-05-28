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
  
end
