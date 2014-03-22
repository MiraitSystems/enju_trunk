# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :public_status do
    id 1
    name "MyString"
    diplay_name "MyString"
    note "MyText"
  end
end
