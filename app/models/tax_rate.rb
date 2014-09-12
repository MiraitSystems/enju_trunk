# coding: utf-8
class TaxRate < ActiveRecord::Base
  attr_accessible :display_name, :end_date, :name, :rate, :rounding, :start_date

  validates_uniqueness_of :name
  validates :name, presence: true
  validates :display_name, presence: true
  validates :rate, presence: true, format: { with: /\A\d+(\.\d)?\z/ }
  validates :rounding, presence: true

  ROUNDING_TYPES = {0 => "切り捨て", 1 => "四捨五入", 2 => "切り上げ"}

  def self.build_tax(date, price)
    tax_rate = TaxRate.where(["start_date <= ? and end_date >= ?", date, date]).first
    if tax_rate.present?
      tax = price * tax_rate.rate * 0.01
      if tax_rate.rounding == 0
        #切り捨て
        tax = tax.truncate
      elsif tax_rate.rounding == 1
        #四捨五入
        tax = tax.round
      elsif tax_rate.rounding == 2
        #切り上げ
        tax = tax.ceil
      end
      item_price = price + tax
      excluding_tax = price
      tax_rate_id = tax_rate.id
    end
    return [item_price, excluding_tax, tax, tax_rate_id]
  end
end
