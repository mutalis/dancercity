class ApplicationController < ActionController::Base
  include TheComments::ViewToken

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  private

  def check_user_settings
    if current_user
      error_message = ''
      if (current_user.current_location == nil)
        error_message = "Please enter your current location."
      end
      if (current_user.email == nil)
        error_message = " Please add an email to your profile."
      end
      if (current_user.dances == [])
        error_message += ' Please choose at least one dance style.'        
      end
      unless error_message == ''
        flash[:error] = error_message
        redirect_to user_path(current_user)
      end
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

end
