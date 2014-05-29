class SendMessage
  include Sidekiq::Worker
  sidekiq_options :backtrace => true

end
