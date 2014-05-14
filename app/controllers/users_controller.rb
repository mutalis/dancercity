class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  # before_action :find_user, except: :index

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

          @users = User.want_dance.match_gender(params[:gender]).any_types_of_dance(params[:user][:dances]).page(params[:page]).per_page(10)
          # puts @users.to_a.inspect
        end
        @pic_urls = []
      else # gets a random set of user profile images when the search is blank.
        @pic_urls = current_user.friends_pics(8).map {|i| i['pic_square']}
      end
    else
      #       no logged 
      @users = User.all.page(params[:page]).per_page(10)
    end
  end

  def show
    # flash[:notice] = 'DF'
  end
  
  # PATCH/PUT /users/1
  def update
    # remove empty items from the dances array
    params[:user][:dances].delete_if {|x| x == ''}
    if @user.update(user_params)
      redirect_to users_path, notice: 'The profile was successfully updated.'
    else
      render action: 'edit'
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.friendly.find params[:id]

    # If an old id or a numeric id was used to find the record, then
    # the request path will not match the user_path, and we should do
    # a 301 redirect that uses the current friendly id.
    if request.path != user_path(@user)
      return redirect_to @user, status: :moved_permanently
    end
  end

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(:visibility, :dances => [])
  end

end
