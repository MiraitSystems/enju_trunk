# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_has_operator do
    id 1
    item_id 1
    user_id 1
    operated_at "2014-02-28 13:18:52"
    library_id ""
    created_at "2014-02-28 13:18:52"
    updated_at "2014-02-28 13:18:52"
  end
end
