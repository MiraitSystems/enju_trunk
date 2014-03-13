# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :claim do
    claim_type_id 1
    note "MyText"
  end
end
