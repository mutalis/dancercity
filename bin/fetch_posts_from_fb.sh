#!/bin/sh

cd /home/mutalis/www.dancercity.net/current/

/usr/local/bin/bundle exec rake 'dc_tools:add_posts_from_api[111998825520170]' RAILS_ENV=production

/usr/local/bin/bundle exec rake 'dc_tools:add_posts_from_api[1388288284726943]' RAILS_ENV=production

/usr/local/bin/bundle exec rake 'dc_tools:add_posts_from_api[tangotecnia]' RAILS_ENV=production
