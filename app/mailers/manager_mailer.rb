class ManagerMailer < ActionMailer::Base
  default from: 'dancercity_manager@dancercity.net',
          reply_to: 'dancercity_manager@dancercity.net'

  def new_invitation(email, message)
    mail(to: email, subject: "You've got a new invitation in Dancer City",
         content_type: 'text/plain',
         body: message)
  end

  def response_to_invitation(email, message)
    mail(to: email, subject: 'Answer to the invitation that you sent - Dancer City',
         content_type: 'text/plain',
         body: message)
  end
end
