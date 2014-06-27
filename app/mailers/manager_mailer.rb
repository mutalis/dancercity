class ManagerMailer < ActionMailer::Base
  default from: ENV!['SMTP_USER']

  def got_new_message(email, message)
    mail(to: email, subject: "You've got a new message on Dancer City",
         content_type: 'text/plain',
         body: message)
  end

  def new_invitation(email, message)
    mail(to: email, subject: "You've got a new invitation in Dancer City",
         content_type: 'text/plain',
         body: message)
  end

  def invitation_sent(email, message)
    mail(to: email, subject: "You have a new conversation in Dancer City",
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
         body: "New DancerCity user: #{user.first_name} #{user.last_name}\n\n Gender: #{user.gender}\n\n Username: #{user.username}\n\n Location: #{user.current_location}")
  end

  def new_sharing_done(user)
    mail(to: 'rodolfo@mutalis.com', subject: 'New sharing was done',
         content_type: 'text/plain',
         body: "New sharing was done by user: #{user.first_name} #{user.last_name}\n\n Gender: #{user.gender}\n\n Username: #{user.username}\n\n Location: #{user.current_location}")
  end
  
  def message_from_site(user,message)
    mail(to: 'rodolfo@mutalis.com', subject: 'Message from DancerCity contact form',
         content_type: 'text/plain',
         body: "New message from: #{user.first_name} #{user.last_name}\n\n Gender: #{user.gender}\n\n Username: #{user.username}\n\n Location: #{user.current_location}\n\n Message: #{message}")
  end
end
