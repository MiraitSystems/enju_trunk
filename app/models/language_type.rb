class LanguageType < ActiveRecord::Base
  attr_accessible :display_name, :name, :note, :position
  default_scope order('position')
end
