class Accept < ActiveRecord::Base
  attr_accessible :item_identifier, :librarian_id, :item_id
  default_scope { order('accepts.id DESC') }
  belongs_to :basket
  belongs_to :item, touch: true
  belongs_to :librarian, class_name: 'User'
  belongs_to :order, touch: true

  validates_presence_of :basket_id
  validate :check_ordered?

  validate do |accept|
    accept.errors.add :base, I18n.t('accept.item_not_found') if accept.item_id.blank?
    if accept.item_id and Accept.where(item_id: accept.item_id).present?
      accept.errors.add :base, I18n.t('accept.already_accepted')
    end
  end

  before_save :accept!, on: :create

  attr_accessor :item_identifier

  paginates_per 10

  def check_ordered?
    unless order
      if item.present?
        errors[:base] << I18n.t('accept.no_ordered')
        return false
      end
    else
      if order.order_list
        unless order.order_list.ordered_at
          errors[:base] << I18n.t('accept.no_ordered')
          return false
        end
      end
    end
    return true
  end

  def accept!
    circulation_status = CirculationStatus.where(name: 'Available On Shelf').first
    item.update_column(:circulation_status_id, circulation_status.id) if circulation_status
    use_restriction = UseRestriction.where(name: 'Limited Circulation, Normal Loan Period').first
    item.use_restriction = use_restriction if use_restriction
  end

end

# == Schema Information
#
# Table name: accepts
#
#  id           :integer          not null, primary key
#  basket_id    :integer
#  item_id      :integer
#  librarian_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

