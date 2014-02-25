FactoryGirl.define do
  factory :type_user, :class => 'AgentType' do |f|
    f.sequence(:name){"User"}
    f.sequence(:display_name){"User"}
  end
end
