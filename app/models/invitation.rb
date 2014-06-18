class Invitation < ActiveRecord::Base
  include TheComments::Commentable

  belongs_to :user
  belongs_to :partner, class_name: "User"
  
  def commentable_state
    "published"
  end
end
