class ExchangeRate < ActiveRecord::Base
  attr_accessible :created_at, :currency_id, :id, :rate, :started_at, :updated_at
  belongs_to :currency

  paginates_per 10

  validates :rate, :presence => true
  validates :started_at, :presence => I18n.t('exchange_rate.invalid_started_at')

  validates_numericality_of :rate, :less_than => 100000000

  searchable do
    text :currency_display_name do
      currency.try(:display_name)
    end 
    time :started_at
  end

end
