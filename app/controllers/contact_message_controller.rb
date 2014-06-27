class ContactMessageController < ApplicationController
  before_action :check_if_logged_in

  def new
    @contact = ContactMessage.new
  end

  def create
    @contact = ContactMessage.new(params[:contact_message])
    if @contact.valid?
      ManagerMailer.message_from_site(current_user, @contact.message).deliver
      redirect_to contact_path, notice: "Thanks #{current_user.first_name} ! Your message has been sent to the customer support team."
    else
      render :new
    end
  end

  def check_if_logged_in
    unless current_user
      session[:stored_path] = request.path
      redirect_to signin_path
    end
  end

end
