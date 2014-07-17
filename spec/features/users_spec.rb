require 'rails_helper'

feature 'Users list', :type => :feature do

  scenario 'fetches more users when scrolling to bottom', js: true do
    FactoryGirl.create_list(:user,11)
    visit '/users?gender=female&user%5Bdances%5D%5B%5D=Tango'
    expect(page).to have_content 'user-1'
    expect(page).not_to have_content 'user-11'
    page.evaluate_script('window.scrollTo(0, document.height)')
    expect(page).to have_content 'user-11'
    # save_and_open_screenshot
  end

end
