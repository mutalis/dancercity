require 'koala'

namespace :dc_tools do
  
  # Use the FB locale as the User locale for all the users.
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

end
