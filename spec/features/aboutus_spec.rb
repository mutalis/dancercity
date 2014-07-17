require 'rails_helper'

feature 'About Us page', :type => :feature do
  scenario 'get access to the page' do
    visit about_path
    expect(page).to have_content 'About Us'
  end
end

# describe "About Us page" do
#   it "get contact form" do
#     visit about_path
#     expect(page).to have_content 'affordability'
#   end
# end
