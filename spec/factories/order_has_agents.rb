# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_has_agent do
    order_id 1
    agent_id 1
    position 1
  end
end
