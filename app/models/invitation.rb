class Invitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :partner, class_name: "User"
end
