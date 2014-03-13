class OrderHasManifestation < ActiveRecord::Base
  attr_accessible :created_at, :id, :manifestation_id, :order_id, :updated_at

  belongs_to :order
  belongs_to :manifestation

  validates_presence_of :order_id, :manifestation_id

end
