require 'test_helper'

class FbNotificationsControllerTest < ActionController::TestCase
  test "should get send" do
    get :send
    assert_response :success
  end

end
