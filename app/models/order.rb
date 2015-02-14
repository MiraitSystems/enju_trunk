class Order < ActiveRecord::Base
  belongs_to :order_list, validate: true
  belongs_to :item, validate: true
  belongs_to :accept

  validates_presence_of :price_string_on_order

  #validates_associated :order_list, :purchase_request
  #validates_presence_of :order_list, :purchase_request
  #validates_uniqueness_of :purchase_request_id, scope: :order_list_id

  before_create :build_order_number

  #acts_as_list scope: :order_list

  paginates_per 10

  #
  def build_order_number
    if self.purchase_order_number.blank?
      Rails.logger.info "numbering order_number"
      self.purchase_order_number = Numbering.do_numbering('order')
    end
  end

  def can_destroy?
    unless self.ordered_at
      return true
    end
    return false
  end
end

#

