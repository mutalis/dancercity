class PagesController < ApplicationController
  def about
  end

  def privacy
  end

  def terms
  end

  def contact
    @contact = ContactMessage.new
  end
end
