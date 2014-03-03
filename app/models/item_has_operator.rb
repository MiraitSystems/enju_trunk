class ItemHasOperator < ActiveRecord::Base
  attr_accessible :created_at, :id, :item_id, :library_id, :note, :operated_at, :updated_at, :user_id

  belongs_to :user
  belongs_to :item
  belongs_to :library

end
