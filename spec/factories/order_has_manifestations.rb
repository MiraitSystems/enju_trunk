# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_has_manifestation do
    id 1
    order_id 1
    manifestation_id 1
    created_at "2014-03-13 10:51:28"
    updated_at "2014-03-13 10:51:28"
  end
end
