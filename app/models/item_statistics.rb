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
  
  def self.aggregation_types
    return I18n.t('statistical_table.item_statistics.aggregation_type').map{|k,v|[v,k]}
  end

  def self.first_aggregations
    return I18n.t('statistical_table.item_statistics.first_aggregation').map{|k,v|[v,k]}
  end

  def self.second_aggregations
    return [[I18n.t('statistical_table.item_statistics.first_aggregation.budget_category_group'), "budget_category_group"]]
  end

  def make_data
    # 集計日付を求める
    if md = self.acquired_at_from.match(/^([0-9]{4})-([0-9]{2})$/)
      acquired_at_from = "#{md[1]}-#{md[2]}-01"
    else
      acquired_at_from = self.acquired_at_from
    end
    if md = self.acquired_at_to.match(/^([0-9]{4})-([0-9]{2})$/)
      day = Date.new(md[1].to_i, md[2].to_i, 1).end_of_month
      acquired_at_to = day.to_s
    else
      acquired_at_to = self.acquired_at_to
    end
    if self.aggregation_type == "statistical_class"
    
    elsif self.aggregation_type == "manifestation_type"
    
    end
    
    items = Item.joins(:manifestation)
    
    # 図書館
    if self.library_id.present?
      items = items.where("items.library_id = ?", self.library_id)
    end
    
    # 出力条件 ItemExinfo
#    if Rails.application.class.parent_name == "EnjuWilmina"
#      items = items.where("items.asset_category_id = ?", self.output_condition)
#    end

    # 横軸
    if self.second_aggregation == "budget_category_group"
      second_aggregation_column = "agents.grade_id"
      second_aggregations =  Keycode.where(:name => 'agent.grade')
    end

    if self.second_aggregation.present?
      items = items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id not in (?)", AcceptType.donate) # 和書 寄贈以外
      items = items.where("manifestations.jpn_or_foreign = 1 and items.accept_type_id not in (?)", AcceptType.donate) # 洋書 寄贈以外
      items = items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id in (?)", AcceptType.donate) # 和書 寄贈
      items = items.where("manifestations.jpn_or_foreign = 1 and items.accept_type_id in (?)", AcceptType.donate) # 洋書 寄贈
    end
    
    
    
    
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
