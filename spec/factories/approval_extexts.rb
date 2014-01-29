# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :approval_extext do
    name "MyString"
    value "MyText"
    approval_id 1
    position 1
    created_at "2014-01-20 16:41:16"
    updated_at "2014-01-20 16:41:16"
  end
end
