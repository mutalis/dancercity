class LikesController < ApplicationController
  before_action :set_user

  # respond_to :js

  rescue_from ActiveRecord::RecordNotFound do |exception|
    message = "User #{params[:id]} not found. Failed Like request from #{current_user.slug}."
    logger.error message
    redirect_to root_path
  end

  def create
    unless current_user.likes?(@user)
      current_user.like!(@user)
      message = like_message(@user)
      ManagerMailer.got_a_like(@user.email, message[0], message[1]).deliver
    end
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

  def like_message(user)
    fb_locale = user.facebook.fql_query("SELECT locale FROM user WHERE uid = me()")
    fb_locale = fb_locale[0]["locale"]

    if (fb_locale =~ Regexp.new('\Aes_')) == 0
      subject = "#{user.first_name} ¡ Tienes un nuevo Like en Dancer City !"

      message = "Hola #{user.first_name}\n\n
      ¡ Tienes un nuevo Like de #{current_user.first_name} #{current_user.last_name} !\n\n
      Puedes ver tus Likes en: http://www.dancercity.net/#{user.slug}\n\n
      Por favor, échale un vistazo al perfil de #{current_user.first_name} en:\n
      http://www.dancercity.net/#{current_user.slug}\n\n
      También puedes ponerte en contacto con #{current_user.first_name} usando el formulario de contacto ubicado en su página de perfil.\n\n
      Happy dancing with DancerCity  : )\n
      El equipo de Dancer City\n
      http://www.dancercity.net\n"
    else
      subject = "#{user.first_name}, You got a new like on Dancer City !"

      message = "Hello #{user.first_name}\n\n
      You got a new Like from #{current_user.first_name} #{current_user.last_name} !\n\n
      You can see your Likes at: http://www.dancercity.net/#{user.slug}\n\n
      Please check out the profile of #{current_user.first_name} at:\n
      http://www.dancercity.net/#{current_user.slug}\n\n
      You can also get in contact with #{current_user.first_name} using the contact form located in the profile page.\n\n
      Happy dancing with DancerCity  : )\n
      The Dancer City Team\n
      http://www.dancercity.net\n"
    end
    [subject, message]
  end

end
