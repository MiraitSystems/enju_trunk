class ItemExinfo < ActiveRecord::Base
  attr_accessible :item_id, :name, :position, :value, :item

  acts_as_list
  default_scope :order => "position"

  belongs_to :item

  has_paper_trail

  def self.add_exinfos(exinfos, item_id)
    return [] if exinfos.blank?
    list = []
    exinfos.each do |key, value|
      name = key.split('_').first 
      kid = key.split('_').last.to_i + 1
      item_exinfo = ItemExinfo.where(
          name: name,
          item_id: item_id
          position: kid
        ).first
      keycode = Keycode.where(:name => "item.#{name}", :keyname => value['value']).try(:first)
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
          item_exinfo = ItemExinfo.create(
            name: name,
            value: keycode.id,
            item_id: item_id,
            position: kid
          )
        else
          item_exinfo = ItemExinfo.create(
            name: name,
            value: value['value'],
            item_id: item_id,
            position: kid
          )
        end
      end
      list << item_exinfo
    end
    return list
  end
end
