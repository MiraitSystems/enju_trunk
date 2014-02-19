class OrderHasPatron < ActiveRecord::Base
  attr_accessible :order_id, :patron_id, :position

  belongs_to :patron
  belongs_to :order

end
