class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:fb_notifications]

  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    if user.visibility == nil
      redirect_to user, notice: 'Please setup your profile'
    else
      redirect_to root_url
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end
  
  def fb_notifications
    if request.get?
      render json: Koala::Facebook::RealtimeUpdates.meet_challenge(params, ENV!['FACEBOOK_UPDATES_TOKEN'])
    else
      # the read method must be used to convert the body request from StringIO to a String
      body_as_a_string = request.body.read
      
      @updates = Koala::Facebook::RealtimeUpdates.new(:app_id => ENV!['FACEBOOK_KEY'], :secret => ENV!['FACEBOOK_SECRET'])

      if @updates.validate_update(body_as_a_string, request.headers)
        render text: 'FB request accepted', status: :accepted
      else
        render text: "not authorized", status: 401
      end
    end
  end
end
