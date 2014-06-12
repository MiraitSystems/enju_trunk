# coding: utf-8
class TaxRate < ActiveRecord::Base
  attr_accessible :display_name, :end_date, :name, :rate, :rounding, :start_date

  validates_uniqueness_of :name
  validates :name, presence: true
  validates :rate, presence: true, format: { with: /^[+-]?[0-9]*[\.]?[0-9]+$/ }
  validates :rate, format: { with: /^[+-]?[0-9]*[\.]?[0-9]+$/ }
  validates :rounding, presence: true

  ROUNDING_TYPES = {0 => "切り捨て", 1 => "四捨五入", 2 => "切り上げ"}
end
