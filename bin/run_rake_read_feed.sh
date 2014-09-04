#!/bin/sh

nohup bundle exec rake 'dc_tools:add_post_from_feed[https://www.facebook.com/feeds/page.php?id=535306009870436&format=rss20]' RAILS_ENV=production &
