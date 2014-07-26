# encoding: utf-8
class CheckoutStatistics
  include ActiveModel::Conversion
  include ActiveModel::Validations
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value) rescue nil
    end
  end
  
  def persisted? ; false ; end
  
  attr_accessor :statistical_table_type, :checked_at_from, :checked_at_to, :aggregation_type, :classification_type_id, :first_aggregation, :second_aggregation
                

  validates_presence_of :checked_at_from
  validates_presence_of :checked_at_to
  validates_presence_of :aggregation_type
  validate :checked_at_from_valid?
  validate :checked_at_to_valid?
  validate :checked_at_range_valid?
  
  def self.first_aggregations
    return [[I18n.t('statistical_table.first_aggregation.user_group'), 'user_group']]
  end
  
  def self.second_aggregations
    return [[I18n.t('statistical_table.second_aggregation.grade'), 'grade']]
  end

private

  def checked_at_from_valid?
    if checked_at_from.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ checked_at_from || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_from
        errors.add(:checked_at_from)
      end
    end
  end

  def checked_at_to_valid?
    if checked_at_to.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ checked_at_to || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_to
        errors.add(:checked_at_to)
      end
    end
  end

  def checked_at_range_valid?
    if checked_at_from.present? && checked_at_to.present?
      if (/^[0-9]{4}-[0-9]{2}$/ =~ checked_at_from && /^[0-9]{4}-[0-9]{2}$/ =~ checked_at_to) || (/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_from && /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_to)
      
        if checked_at_from > checked_at_to
          errors.add(:checked_at_from)
        end
      else
        errors.add(:checked_at_from)
      end
    end
  end

end
