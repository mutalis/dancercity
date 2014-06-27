class ContactMessageController < ApplicationController

  def create
    @contact = ContactMessage.new(params[:contact_message])
    if @contact.valid?
      ManagerMailer.message_from_site(current_user, @contact.message).deliver
      redirect_to contact_path, notice: "Thanks #{current_user.name}! We've received your message."
    else
      render 'pages/contact'
    end
  end
end
