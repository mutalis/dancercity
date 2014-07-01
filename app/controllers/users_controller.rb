# encoding: UTF-8

require 'will_paginate/array'

class UsersController < ApplicationController
  before_action :check_user_settings, except: [:show, :update]
  before_action :set_user, only: [:show, :update]

  # GET /
  def index
    if current_user

      # Show the post to wall form
      if session[:fb_post]
        @fb_post = session[:fb_post]
        session[:fb_post] = nil
        permissions = current_user.facebook.get_connections('me','permissions')
        @has_wallpost_permission = permissions[0]['publish_stream'].to_i == 1 ? true : false
        if @has_wallpost_permission
          current_user.facebook.put_connections("me", "feed", :message => @fb_post)
          flash.now[:notice] = 'Your message was successfully posted to your Facebook wall.'
          ManagerMailer.new_sharing_done(current_user).deliver
        else
          flash.now[:error] = 'Please allow Dancer City to post a message on your Facebook wall. Please try again.'
        end
      else
        fb_locale = current_user.facebook.fql_query("SELECT locale FROM user WHERE uid = me()")
        fb_locale = fb_locale[0]["locale"]

        if (fb_locale =~ Regexp.new('\Aes_')) == 0
          @fb_post = "Si buscas pareja de baile, o quieres conocer a nuevas personas, en Dancer City las puedes encontrar.\n\n
          Dancer City es un servicio gratis especialmente diseñado para este fin.\n
          Entra al Sitio http://www.dancercity.net para conocer más detalles.\n
          - Dancer City es una nueva Web App para Facebook para quienes les gusta bailar.\n
          - Encuentra fácil, rápido y automáticamente a nuevas personas para bailar.\n
          - Puedes conocer nuevas personas para bailar en función de las preferencias que definas.\n
          - Encuentra a gente que baila:\n
            Bachata, Cha-cha-chá, Conga, Cumbia, Danzón, Fox-Trot, Jazz, Kizomba, Merengue, Pasodoble, Rock and roll, Rumba, Salsa, Swing, Tango\n
          - Todos estos servicios son Gratis !\n"
        else
          @fb_post = "Dancer City is a new Web App for Facebook for those who like to dance.\n\nSign in at: http://www.dancercity.net\n
          - Meet people that enjoy of the ballroom dancing and make new friends using your Facebook account.\n
          - Invite someone to dance based on the dancer profile that you are looking for.\n
          - Find people who like to dance:\n
            Bachata, Cha-cha-chá, Conga, Cumbia, Danzón, Fox-Trot, Jazz, Kizomba, Merengue, Pasodoble, Rock and roll, Rumba, Salsa, Swing, Tango.\n
          - All this services are Free !\n"
        end
      end

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
    
          @users = User.no_user(current_user.username).want_dance.match_gender(params[:gender]).any_types_of_dance(params[:user][:dances])

          # The user can send an invitation only if him don't have a previous invitation with pending status for the same recipient.
          @users = current_user.remove_users_with_pending_invitations(@users)
          
          total_num_results_found = @users.count
          
          # paginate the results
          @users = @users.paginate(:page => params[:page], :per_page => 10)
          
          if @users.empty?
            flash.now[:error] = "At this time there is not any dancer that match your search criteria. Please try again later."
          else
            flash.now[:notice] = "#{total_num_results_found} dancers were found."
          end
        end
      else
      end # unless
    else # no logged
      # gets a set of user profile images when no logged.
      @pic_urls = User.want_dance.limit(32).reorder(created_at: :desc).map {|i| i['image']}
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
      redirect_to root_path, notice: 'Your profile was successfully updated.'
    else
      render action: 'show'
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    if current_user
      @user = current_user
    else
      session[:stored_path] = request.path
      redirect_to signin_path
    end
  end

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(:visibility, :email, :longitude, :latitude, :current_location, :dances => [])
  end

end
