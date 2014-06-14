class ManagerMailer < ActionMailer::Base
  default from: ENV!['SMTP_USER']

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

  def new_signin_notification(user)
    mail(to: 'rodolfo@mutalis.com', subject: 'New DancerCity Sign in',
         content_type: 'text/plain',
         body: "New DancerCity user: #{user.first_name} #{user.last_name}\n Gender: #{user.gender}\n
         Dances: #{user.dances}\n Location: #{user.current_location}")
  end
end
