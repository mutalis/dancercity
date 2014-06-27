class ContactMessage
  include ActiveModel::Model

  attr_accessor :message

  validates :message, presence: true, length: { maximum: 3000 }
end
