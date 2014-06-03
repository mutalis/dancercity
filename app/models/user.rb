class User < ActiveRecord::Base
  extend FriendlyId

  after_create :invite_friends

  has_many :invitations
  has_many :partners, through: :invitations

  has_many :sent_invitations, class_name: "Invitation", foreign_key: "partner_id", before_add: :check_for_duplicate_invitations
  has_many :inverse_partners, through: :sent_invitations, source: :user

  has_many :accepted_invitations, -> { where status: 'accepted' }, class_name: "Invitation"
  has_many :pending_invitations, -> { where status: 'pending' }, class_name: "Invitation"
  has_many :sent_accepted_invitations, -> { where status: 'accepted' }, class_name: "Invitation", foreign_key: "partner_id"

  # Throws an exception if a new invitation is a duplicate from a previous one sent to
  # the same person with the same date.
  def check_for_duplicate_invitations(invitation)
    result = sent_invitations.where({ date: invitation.date, user: invitation.user })
    if (result) && (result.count >= 1)
      # throws an exception
      raise "Invalid invitation, it's a duplicate."
    end
  end

  # validates :username, uniqueness: true, presence: true,
  #           exclusion: {in: %w[signout fb_updates]}

  friendly_id :username, use: [:slugged, :history]

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
      user.username = auth.info.nickname
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.image = auth.info.image
      # user.email = auth.info.email
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.gender = auth.extra.raw_info.gender

      # get user location via Koala only if the location data exists
      if auth.extra.raw_info.location.respond_to? :id
        graph = Koala::Facebook::API.new(auth.credentials.token)
        current_location = graph.get_object(auth.extra.raw_info.location.id)
        user.current_location = current_location['name']
        user.longitude = current_location['location']['longitude']
        user.latitude = current_location['location']['latitude']
      end
      user.save!
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
    facebook { |fb| fb.fql_query("select uid from user where uid in (select uid2 from friend where uid1 = me()) limit #{uids_number}") }
    # [{"uid"=>"100000334781484"}, {"uid"=>"100002981817359"}]
  end

  def friends_count
    facebook { |fb| fb.get_connections("me", "friends").size }
  end

  protected

  # Send a private message to the friends of the user to invite them to sign up to Dancer City.
  def invite_friends
    logger.info 'Send FB sign up invitations'
    SendMessage.perform_async(self.uid, self.friends_uids(30), self.oauth_token)
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
