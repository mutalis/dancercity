require 'will_paginate/array'

class UsersController < ApplicationController
  before_action :set_user, only: [:show, :update]

  # GET /
  def index
    if current_user
    
      # gets the users that match the search criteria
      unless params[:user].blank? && params[:gender].blank?
        valid_genders = Regexp.new('(\Afemale\z)|(\Amale\z)')
    
        valid_dances = Regexp.new('(\ABachata\z)|(\ACha-cha-chá\z)|(\AConga\z)|(\ACumbia\z)|(\ADanzón\z)|(\AFox-Trot\z)|(\AJazz\z)|(\AKizomba\z)|(\AMerengue\z)|(\APasodoble\z)|(\ARock and roll\z)|(\ARumba\z)|(\ASalsa\z)|(\ASwing\z)|(\ATango\z)')
    
        # Gender validation, if the gender isn't valid it's assigned nil.
        if (params[:gender] =~ valid_genders) == nil
          params[:gender] = nil
        end
    
        # Dances validation, removing all not valid dances using a case sensitive regex.
        params[:user][:dances].keep_if {|i| i =~ valid_dances }
    
        if (params[:gender] != nil) && (params[:user][:dances] != [])
          # current_user.longitude, current_user.latitude
    
          # @users = User.match_gender().any_types_of_dance().close_to()
          # @users = User.want_dance.match_gender().any_types_of_dance().close_to()
    
          @users = User.no_user(@current_user.username).want_dance.match_gender(params[:gender]).any_types_of_dance(params[:user][:dances])

          # The user can send an invitation only if him don't have a previous invitation with pending status for the same recipient.
          @users = @current_user.remove_users_with_pending_invitations(@users).paginate(:page => params[:page], :per_page => 10)
        end
        @pic_urls = []
      else # gets a set of user profile images when the search form is blank.
        @pic_urls = @current_user.friends_pics(12).map {|i| i['pic_square']}
      end
    else # no logged 
      # gets a set of user profile images when no logged.
      @pic_urls = User.find_by(username: 'tangohoy1').friends_pics(32).map {|i| i['pic_square']}
    end
  end

  # GET /:id
  def show
  end
  
  # PATCH/PUT /:id
  def update
    # remove empty items from the dances array
    params[:user][:dances].delete_if {|x| x == ''}

    if @user.update(user_params)
      redirect_to root_path, notice: 'The profile was successfully updated.'
    else
      render action: 'show'
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    # @user = User.friendly.find params[:id]
    @user = current_user

    # if the user is not logged in redirect to the login page.
    if @user
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the user_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if request.path != user_path(@user)
        return redirect_to @user, status: :moved_permanently
      end
    else
      redirect_to root_path
    end
    # 
    # if @current_user.slug != @user.slug
    #   raise "Invalid user access."
    # end
  end

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(:visibility, :dances => [])
  end

end
