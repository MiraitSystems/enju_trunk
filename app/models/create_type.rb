require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'create_type')
class CreateType < ActiveRecord::Base
  attr_accessible :display
end
