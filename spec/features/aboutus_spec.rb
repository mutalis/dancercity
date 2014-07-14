require 'rails_helper'

feature "About Us page", :type => :feature do
  scenario "get contact form" do
    visit root_path
    expect(page).to have_content 'engine'
  end
end

# describe "About Us page" do
#   it "get contact form" do
#     visit about_path
#     expect(page).to have_content 'affordability'
#   end
# end
