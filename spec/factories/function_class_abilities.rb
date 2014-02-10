# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :function_class_ability do
    function_class { FactoryGirl.create(:function_class) }
    function { FactoryGirl.create(:function) }
    ability 1
  end
end
