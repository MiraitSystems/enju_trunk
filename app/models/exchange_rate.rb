class ExchangeRate < ActiveRecord::Base
  attr_accessible :created_at, :currency_id, :id, :rate, :started_at, :updated_at, :orders_started_at, :orders_ended_at
  attr_accessor :orders_started_at, :orders_ended_at

  belongs_to :currency

  paginates_per 10

  validates_uniqueness_of :currency_id
  validates :rate, :presence => true
  validates :started_at, :presence => I18n.t('exchange_rate.invalid_started_at')
  # validate :check_order_date
  # validate :happened_at_is_valid_datetime

  validates_numericality_of :rate, :less_than => 100000000

  searchable do
    text :currency_display_name do
      currency.try(:display_name)
    end
    string :currency_id
    time :started_at
  end

#  def happened_at_is_valid_datetime
#    errors.add(:orders_started_at, 'must be a valid datetime') if ((DateTime.parse(orders_started_at) rescue ArgumentError) == ArgumentError)
#  end

=begin
  def check_order_date#(start_at, end_at)
    if orders_started_at and orders_ended_at
      if orders_started_at > orders_ended_at
        return false
      end
      return true
    end
  end
=end

  def self.check_order_date(start_at, end_at)
    logger.error "############# check_orader_date now!! ##############"
    if start_at.present? && end_at.present?
      begin
        start_at_new = Time.zone.parse(start_at)
        end_at_new = Time.zone.parse(end_at)
      rescue ArgumentError
        raise I18n.t('activerecord.attributes.order.order_day')+I18n.t('exchange_rate.invalid_started_at')
      end
      if start_at > end_at
        raise I18n.t('activerecord.attributes.order.order_day')+I18n.t('exchange_rate.invalid_started_at')
      end
    else
      raise I18n.t('activerecord.attributes.order.order_day')+I18n.t('exchange_rate.invalid_started_at')
    end
  end
end
