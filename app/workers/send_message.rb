class SendMessage
  include Sidekiq::Worker
  sidekiq_options :backtrace => true

  def perform(sender_uid, friends_uids, sender_auth_token)

    sender_chat_id   = "-#{sender_uid}@chat.facebook.com"

    friends_uids.each do |receiver|

      receiver_chat_id   = "-#{receiver["uid"]}@chat.facebook.com"
      jabber_message   = Jabber::Message.new(receiver_chat_id, facebook_message)
      jabber_message.subject = "Dancer City"

      client = Jabber::Client.new(Jabber::JID.new(sender_chat_id))
      client.connect
      client.auth_sasl(Jabber::SASL::XFacebookPlatform.new(client,
      ENV!['FACEBOOK_KEY'], sender_auth_token, ENV!['FACEBOOK_SECRET']), nil)
      client.send(jabber_message)
      client.close
      sleep(rand(120)+120) # Wait to deliver the next message from 2 until 4 mins.
    end

  rescue RuntimeError
    raise FacebookChatAccessDenied, "No access to Facebook Chat"
  end

  def facebook_message
    "Invitation to join to Dancer City\n\n
    See you there. Sign in at: http://dancercity.net\n\n
    Dancer City is a new Web App for Facebook for those who like to dance.\n\n
    Meet people that enjoy of the ballroom dancing and make new friends using your Facebook account.\n\n
    Invite someone to dance based on the dancer profile that you are looking for.\n\n
    The party is on !  And you are invited to join it."
  end
end
