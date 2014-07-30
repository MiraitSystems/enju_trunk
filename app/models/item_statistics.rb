# encoding: utf-8
class ItemStatistics
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
  
  attr_accessor :statistical_table_type, :acquired_at_from, :acquired_at_to, :aggregation_type,
                :money_aggregation, :remove_aggregation,
                :library_id, :output_condition,
                :first_aggregation, :second_aggregation

  validates_presence_of :acquired_at_from
  validates_presence_of :acquired_at_to
  validates_presence_of :aggregation_type
  validate :acquired_at_from_valid?
  validate :acquired_at_to_valid?
  validate :acquired_at_range_valid?
  
  def self.output_conditions
    return Keycode.where(:name => "item.asset_category")
  end

  def self.aggregation_types
    return I18n.t('statistical_table.item_statistics.aggregation_type').map{|k,v|[v,k]}
  end

  def self.first_aggregations
    return I18n.t('statistical_table.item_statistics.first_aggregation').map{|k,v|[v,k]}
  end

  def self.second_aggregations
    return [[I18n.t('statistical_table.item_statistics.first_aggregation.budget_category_group'), "budget_category_group"]]
  end

private

  def acquired_at_from_valid?
    if acquired_at_from.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_from || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_from
        errors.add(:acquired_at_from)
      end
    end
  end

  def acquired_at_to_valid?
    if acquired_at_to.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_to || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_to
        errors.add(:acquired_at_to)
      end
    end
  end

  def acquired_at_range_valid?
    if acquired_at_from.present? && acquired_at_to.present?
      if (/^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_from && /^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_to) || (/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_from && /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_to)
      
        if acquired_at_from > acquired_at_to
          errors.add(:acquired_at_from)
        end
      else
        errors.add(:acquired_at_from)
      end
    end
  end

end
