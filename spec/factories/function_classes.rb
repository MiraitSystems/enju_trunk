# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :function_class do |f|
    f.sequence(:display_name) {|n| "Test #{n}" }
    f.sequence(:name) {|n| "test#{n}" }
    position 1
  end
end
