FactoryGirl.define do
  factory :agent, :class => 'Agent' do |f|
    f.sequence(:full_name){|n| "full_name_#{n}"}
    f.agent_type_id{AgentType.find_by_name('Person').id}
    f.country_id{Country.first.try(:id) || FactoryGirl.create(:country).id}
    f.language_id{Language.first.try(:id) || FactoryGirl.create(:language).id}
  end

  factory :adult_agent, :class => 'Agent' do |f|
    f.sequence(:full_name){|n| "adult_#{n}"}
    f.agent_type_id{AgentType.find_by_name('Person').id}
    f.country_id{Country.first.id || FactoryGirl.create(:country).id}
    f.language_id{Language.first.id || FactoryGirl.create(:language).id}
    f.date_of_birth DateTime.parse("#{DateTime.now.year-25}0101")
  end

  factory :student_agent, :class => 'Agent' do |f|
    f.sequence(:full_name){|n| "student_#{n}"}
    f.agent_type_id{AgentType.find_by_name('Person').id}
    f.country_id{Country.first.id || FactoryGirl.create(:country).id}
    f.language_id{Language.first.id || FactoryGirl.create(:language).id}
    f.date_of_birth{DateTime.parse("#{DateTime.now.year-16}0101")}
  end

  factory :juniors_agent, :class => 'Agent' do |f|
    f.sequence(:full_name){|n| "juniors_#{n}"}
    f.agent_type_id{AgentType.find_by_name('Person').id}
    f.country_id{Country.first.id || FactoryGirl.create(:country).id}
    f.language_id{Language.first.id || FactoryGirl.create(:language).id}
    f.date_of_birth{DateTime.parse("#{DateTime.now.year-13}0101")}
  end

  factory :elements_agent, :class => 'Agent' do |f|
    f.sequence(:full_name){|n| "elements_#{n}"}
    f.agent_type_id{AgentType.find_by_name('Person').id}
    f.country_id{Country.first.id || FactoryGirl.create(:country).id}
    f.language_id{Language.first.id || FactoryGirl.create(:language).id}
    f.date_of_birth{DateTime.parse("#{DateTime.now.year-7}0101")}
  end

  factory :children_agent, :class => 'Agent' do |f|
    f.sequence(:full_name){|n| "children_#{n}"}
    f.agent_type_id{AgentType.find_by_name('Person').id}
    f.country_id{Country.first.id || FactoryGirl.create(:country).id}
    f.language_id{Language.first.id || FactoryGirl.create(:language).id}
    f.date_of_birth{DateTime.parse("#{DateTime.now.year-2}0101")}
  end
  
end

FactoryGirl.define do
  factory :invalid_agent, :class => 'Agent' do |f|
  end
end
