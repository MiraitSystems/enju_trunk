class ItemExtext < ActiveRecord::Base
  attr_accessible :item_id, :name, :position, :type_id, :value

  belongs_to :item

  acts_as_list
  default_scope :order => "position"
end
