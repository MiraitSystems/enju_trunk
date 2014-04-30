# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sub_carrier_type do
    name "MyString"
    display_name "MyString"
    carrier_type_id 1
    nacsis_identifier "MyString"
    note "MyString"
    position 1
  end
end
