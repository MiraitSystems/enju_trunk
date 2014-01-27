# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :title_type do
    id 1
    name "MyString"
    display_name "MyText"
    note "MyText"
    position 1
    created_at "2014-01-24 17:49:47"
    updated_at "2014-01-24 17:49:47"
  end
end
