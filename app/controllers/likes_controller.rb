class LikesController < ApplicationController
  before_action :set_user

  respond_to :js

  rescue_from ActiveRecord::RecordNotFound do |exception|
    message = "User #{params[:id]} not found. Failed Like request from #{current_user.slug}."
    logger.error message
    redirect_to root_path
  end

  def create
    current_user.like!(@user) unless current_user.likes?(@user)
  end

  # def show
  #   @users = current_user.likers(User)
  # end
  private

  def set_user
    if current_user
      @user = User.friendly.find(params[:id])
    else
      session[:stored_path] = request.path
      redirect_to signin_path
    end
  end

end
