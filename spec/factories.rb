FactoryGirl.define do
  factory :user do
    sequence(:username) {|n| "user-#{n}"}
    email { "#{username}@mutalis.com"}
    dances ['Tango']
    current_location 'Mexico City, Mexico'
    gender 'female'
    visibility 'open'
    first_name {"#{username}"}
    last_name {"#{username}-lastname"}
  end
end
