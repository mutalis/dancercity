# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :post do
    title "MyString"
    url "MyString"
    summary "MyText"
    published_at "2014-08-28 15:47:42"
    slug "MyString"
    user nil
  end
end
