class ExchangeRate < ActiveRecord::Base
  attr_accessible :created_at, :currency_id, :id, :rate, :started_at, :updated_at, :orders_started_at, :orders_ended_at
  attr_accessor :orders_started_at, :orders_ended_at

  belongs_to :currency

  paginates_per 10

  validates_uniqueness_of :currency_id
  validates :rate, :presence => true
  validates :started_at, :presence => I18n.t('exchange_rate.invalid_started_at')

  validates_numericality_of :rate, :less_than => 100000000

  searchable do
    text :currency_display_name do
      currency.try(:display_name)
    end
    string :currency_id
    time :started_at
  end

  def self.check_order_date(start_at, end_at)
    if start_at.present? && end_at.present?
      begin
        start_at_new = Time.zone.parse(start_at)
        end_at_new = Time.zone.parse(end_at)
      rescue ArgumentError
        raise I18n.t('activerecord.attributes.order.ordered_at')+I18n.t('exchange_rate.invalid_started_at')
      end
      if start_at > end_at
        raise I18n.t('activerecord.attributes.order.ordered_at')+I18n.t('exchange_rate.invalid_started_at')
      end
    else
      raise I18n.t('activerecord.attributes.order.ordered_at')+I18n.t('exchange_rate.invalid_started_at')
    end
  end

end
