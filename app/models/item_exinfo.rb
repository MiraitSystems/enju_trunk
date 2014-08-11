class ItemExinfo < ActiveRecord::Base
  attr_accessible :item_id, :name, :position, :value, :item

  acts_as_list
  default_scope :order => "position"

  belongs_to :item

  has_paper_trail

  def self.add_exinfos(exinfos, item_id)
    return [] if exinfos.blank?
    list = []
    position = 1
    exinfos.each do |key, value|
      item_exinfo = ItemExinfo.where(
          name: key,
          item_id: item_id
        ).first
      keycode = Keycode.where(:name => "item.#{key}", :keyname => value['value']).try(:first)
      if item_exinfo
        if value.blank?
          item_exinfo.destroy
          next
        else
          if keycode
            item_exinfo.value = keycode.id
          else
            item_exinfo.value = value['value']
          end
        end
      else
        next if value.blank?
        if keycode 
          item_exinfo = ItemExinfo.new(
            name: key,
            value: keycode.id,
            item_id: item_id
          )
        else
          item_exinfo = ItemExinfo.new(
            name: key,
            value: value['value'],
            item_id: item_id
          )
        end
      end
      item_exinfo.position = position
      item_exinfo.save
      list << item_exinfo
      position += 1
    end
    return list
  end
end
