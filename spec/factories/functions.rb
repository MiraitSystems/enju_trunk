# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :function do
    controller_name 'ManifestationsController'
    display_name 'Manifestations'
    action_names "read:index,show\nupdate:new,create,edit,update\ndelete:destroy\n"
    position 1
  end
end
