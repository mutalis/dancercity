require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "close users" do
    far_user = User.create!(
      username:  "Far user",
      latitude:   40.000000,
      longitude: -77.000000
    )

    close_user = User.create!(
      username:"Close user",
      latitude:   39.010000,
      longitude: -75.990000
    )

    close_users = User.close_to(39.000000, -76.000000).load

    assert_equal 1,          close_users.size
    assert_equal close_user, close_users.first
    puts close_users.inspect
  end
end
