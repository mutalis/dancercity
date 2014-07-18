# encoding: UTF-8

class User < ActiveRecord::Base
  include TheComments::User
  extend FriendlyId

  after_create :notify_admin_by_email, :send_welcome_message

  has_many :invitations
  has_many :partners, through: :invitations

  has_many :sent_invitations, class_name: "Invitation", foreign_key: "partner_id", before_add: :check_for_duplicate_invitations
  has_many :inverse_partners, through: :sent_invitations, source: :user

  has_many :accepted_invitations, -> { where status: 'accepted' }, class_name: "Invitation"
  has_many :pending_invitations, -> { where status: 'pending' }, class_name: "Invitation"
  has_many :sent_accepted_invitations, -> { where status: 'accepted' }, class_name: "Invitation", foreign_key: "partner_id"
  has_many :sent_pending_invitations, -> { where status: 'pending' }, class_name: "Invitation", foreign_key: "partner_id"
  
  validates :username, uniqueness: true, presence: true,
            exclusion: {in: %w[signout fb_updates new admin about privacy terms comments]}

  validates :email, :email => {:strict_mode => true}

  validates_presence_of :dances, message: 'Choose at least one dance style'

  validates_presence_of :current_location, message: 'Please enter your current location.'

  validates_presence_of :gender, :visibility

  friendly_id :username, use: [:slugged, :history]

  acts_as_liker
  acts_as_likeable

  def admin?
    false
    # self == User.find_by username: 'tangohoy1'
  end

  def comments_admin?
    admin?
  end

  # Throws an exception if a new invitation is a duplicate from a previous one sent to
  # the same person with the same date.
  def check_for_duplicate_invitations(invitation)
    result = sent_invitations.where({ date: invitation.date, user: invitation.user })
    if (result) && (result.count >= 1)
      # throws an exception
      raise "Invalid invitation, it's a duplicate."
    end
  end

  def has_pending_invitations?(user)
    result = sent_pending_invitations.where({ user: user })
    if (result) && (result.count >= 1)
      true
    else
      false
    end
  end

  def remove_users_with_pending_invitations(users)
    users.delete_if { |u| self.has_pending_invitations?(u) }
  end

  default_scope { order(created_at: :asc) }

  scope :want_dance, -> { where.not("visibility = ?", 'close') }

  scope :no_user, -> (username) { where.not("username = ?", username) }

  scope :match_gender, -> (gender) { where("gender = ?", gender) }

  # Find all the users that have any of the dances of the given array.
  scope :any_types_of_dance, -> (dances) { where('dances && ARRAY[?]', dances) }

  # Find all the users that have all the dances of the given array.
  scope :all_the_types_of_dance, -> (dances) { where('dances @> ARRAY[?]', dances) }

  scope :close_to, -> (longitude, latitude, distance_in_meters = 2000) {
    where(%{
      ST_DWithin(
        ST_GeographyFromText(
          'SRID=4326;POINT(' || users.longitude || ' ' || users.latitude || ')'
        ),
        ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
        %d
      )
    } % [longitude, latitude, distance_in_meters])
  }

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      # if the FB username is not defined use the Uid as the username
      if auth.info.respond_to? :nickname
        user.username = auth.info.nickname
      else
        user.username = auth.uid
      end
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.image = auth.info.image
      if auth.info.respond_to? :email
        user.email = auth.info.email
      end
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.gender = auth.extra.raw_info.gender
      user.locale = auth.extra.raw_info.locale

      # get user location via Koala only if the location data exists
      if auth.extra.raw_info.location.respond_to? :id
        graph = Koala::Facebook::API.new(auth.credentials.token)
        current_location = graph.get_object(auth.extra.raw_info.location.id)
        user.current_location = current_location['name']
        user.longitude = current_location['location']['longitude']
        user.latitude = current_location['location']['latitude']
      end
      user.save!(validate: false)
    end
  end

  def facebook
    @facebook ||= Koala::Facebook::API.new(oauth_token)
    block_given? ? yield(@facebook) : @facebook
  rescue Koala::Facebook::APIError => e
    logger.info e.to_s
    nil
  end
  
  def friends_pics(pics_number)
    facebook { |fb| fb.fql_query("select pic_square from user where uid in (select uid2 from friend where uid1 = me()) limit #{pics_number}") }
  end
  
  def friends_uids(uids_number = 10000000)
    facebook { |fb| fb.fql_query("select uid, first_name from user where uid in (select uid2 from friend where uid1 = me()) limit #{uids_number}") }
    # [{"uid"=>"504589798", "first_name"=>"Lorena"}, {"uid"=>"504773652", "first_name"=>"Grace"}]
  end

  def friends_count
    facebook { |fb| fb.get_connections("me", "friends").size }
  end

  def friends_invitations_sent?
    self.friends_invitations_sent
  end

  # Send a private message to the friends of the user to invite them to sign up to Dancer City.
  def invite_friends
    logger.info 'Send FB sign up invitations'
    SendMessage.perform_async(self.uid, self.friends_uids, self.oauth_token)
    self.friends_invitations_sent = true
    self.save!
  end

  # Send email with the settings of the user.
  def notify_admin_by_email
    ManagerMailer.new_signin_notification(self).deliver
  end
  
  # Send email with the settings of the user.
  def send_welcome_message
    if (locale =~ Regexp.new('\Aes_')) == 0
      subject = "#{self.first_name} ¡ Bienvenido a Dancer City !"

      message = "Hola #{self.first_name}\n\n
¡ Gracias por unirte a la comunidad de Dancer City !\n\n
Tu cuenta ha sido creada. A partir de ahora te será más fácil contactar a personas que les gusta bailar.\n\n
Puedes acceder a tu página de perfil en:\n\n
http://www.dancercity.net/#{self.slug}\n\n
Por favor síguenos en nuestra página en Facebook para estar al día de lo que sucede en la comunidad Dancer City.\n\n
https://www.facebook.com/dancercity\n\n
Si tienes alguna duda o comentario sobre Dancer City, contáctanos a través de nuestra página en Facebook, o en nuestra página de contacto en Dancer City:\n\n
http://www.dancercity.net/contact\n\n
Estamos trabajando en nuevas funcionalidades para Dancer City. Te agradecemos nos envíes tus comentarios sobre como mejorar Dancer City, y las funcionalidades que te gustaría que se agregaran.\n\n
Gracias,\n
El equipo de Dancer City\n
http://www.dancercity.net\n"
    else
      subject = "#{self.first_name}, Welcome to Dancer City !"

      message = "Hello #{self.first_name}\n\n
Thanks for joining Dancer City !\n\n
Your account has been created. From now on it will be easier meet people that enjoy dancing.\n\n
You can access your profile page at:\n\n
http://www.dancercity.net/#{self.slug}\n\n
Please follow us at our Facebook page to know what's up in the Dancer City community.\n\n
https://www.facebook.com/dancercity\n\n
If you'd like to talk to us, please feel free to contact us through our Facebook page or using our contact form at:\n\n
http://www.dancercity.net/contact\n\n
We're working on new features for Dancer City. We'd love to hear how we can make Dancer City even better for you.\n\n
Thank you,\n
The Dancer City Team\n
http://www.dancercity.net\n"
    end
    ManagerMailer.welcome_message(self.email, subject, message).deliver
  end

  # def send_facebook_message
  #   # receiver_chat_id   = "-#{receiver_uid}@chat.facebook.com"
  #   # receiver_chat_id   = "-100002981817359@chat.facebook.com"
  #   receiver_chat_id   = "-#{self.uid}@chat.facebook.com"
  #   sender_chat_id = "-#{self.uid}@chat.facebook.com"
  #   
  #   jabber_message   = Jabber::Message.new(receiver_chat_id, facebook_message)
  #   jabber_message.subject = "Tango MX"
  # 
  #   client = Jabber::Client.new(Jabber::JID.new(sender_chat_id))
  #   client.connect
  #   client.auth_sasl(Jabber::SASL::XFacebookPlatform.new(client,
  #    ENV!['FACEBOOK_KEY'], self.oauth_token, ENV!['FACEBOOK_SECRET']), nil)
  #   client.send(jabber_message)
  #   client.close
  # rescue RuntimeError
  #   raise FacebookChatAccessDenied, "No access to Facebook Chat"
  # end
end
