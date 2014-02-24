class OrderHasAgent < ActiveRecord::Base
  attr_accessible :order_id, :agent_id, :position

  belongs_to :agent
  belongs_to :order

end
