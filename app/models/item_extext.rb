class ItemExtext < ActiveRecord::Base
  attr_accessible :item_id, :name, :position, :type_id, :value

  belongs_to :item

  acts_as_list :scope => [:item_id, :name]
  default_scope :order => "position"

  def self.add_extexts(extexts, item_id)
    return [] if extexts.blank?
    list = []
    extexts.each do |key, value|
      next if value['value'].blank?
      name = key.split('_').first
      kid = key.split('_').last.to_i + 1
      item_extext = ItemExtext.where(
        name: name,
        item_id: item_id,
        position: kid
      ).first
      if item_extext
        if value['value'].blank?
          item_extext.destroy
          next
        else
          item_extext.value   = value['value']
          item_extext.type_id = value['type_id']
        end 
      else
        next if value['value'].blank?
        item_extext = ItemExtext.create(
          name: name,
          value: value['value'],
          type_id: value['type_id'],
          item_id: item_id,
          position: kid
        )   
      end 
      list << item_extext
    end 
    return list
  end 
end
