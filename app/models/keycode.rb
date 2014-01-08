class Keycode < ActiveRecord::Base
  attr_accessible :display_name, :ended_at, :keyname, :name, :started_at, :v
  default_scope :order => 'name ASC, started_at ASC'

end
