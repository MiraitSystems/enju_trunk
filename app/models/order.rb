class Order < ActiveRecord::Base
  belongs_to :order_list, validate: true
  belongs_to :item, validate: true
  belongs_to :accept

  validates_presence_of :price_string_on_order

  validate :validate_purchase_order_number

  validates_associated :order_list
  validates_presence_of :order_list
  #validates_uniqueness_of :purchase_request_id, scope: :order_list_id

  before_create :build_order_number
  after_save :update_preorder_to_item_circulation_status
  after_destroy :update_circulation_status

  #acts_as_list scope: :order_list

  paginates_per 10

  def validate_purchase_order_number
    if self.purchase_order_number.present?
      unless /\A[a-zA-Z0-9]+\z/ =~ purchase_order_number
        errors.add(:purchase_order_number, I18n.t('order.en_expected'))
      end
    end
  end

  def build_order_number
    if self.purchase_order_number.blank?
      Rails.logger.info "numbering order_number"
      self.purchase_order_number = Numbering.do_numbering('order')
    end
  end

  def can_cancel?
    if self.order_list.ordered?
      unless self.accept_id.present?
        unless self.canceled_at.present?
          return true
        end
      end
    end
    return false
  end

  private
  def update_circulation_status
    # on destroy
    if self.item_id
      status = CirculationStatus.where(name: "On Order").first rescue nil
      if status
        item.circulation_status = status
        item.save!
      end
    end
  end

  def update_preorder_to_item_circulation_status
    if self.item_id
      pre_order_status = CirculationStatus.where(name: "On PrepareOrder").first rescue nil
      if pre_order_status
        item.circulation_status = pre_order_status
        item.save!
      end
    end
  end
end

#

