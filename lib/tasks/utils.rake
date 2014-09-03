require 'koala'

namespace :dc_tools do
  
  desc "Use the FB locale as the User locale for all the users."
  task(setup_locale: :environment) do
    @graph = Koala::Facebook::GraphAPI.new

    User.find_each(:batch_size => 1000) do |user|
      begin
        if user.locale == nil
          user.locale = @graph.get_object(user.uid)['locale']

          if !user.save
            puts "Error to update the locale for user id #{user.id}"
          end
        end
      rescue Exception => e
        puts e.message
      end
    end
  end

  desc "Add entries to the Post model using Feeds. It keep running as a daemon."
  task(:add_post_from_feed, [:feed_url] => :environment) do |task, args|
    Post.add_from_feed_daemon(args.feed_url)
  end

end
