# -*- encoding: utf-8 -*-
class AddColumnItemsCirculationRestrictionId < ActiveRecord::Migration
  def change
    if Item.exists?
      keycode = Keycode.where(:name => 'item.circulation_restriction', :v => '0').try(:first) || 
                Keycode.create!(:name => 'item.circulation_restriction', :display_name => '資料状況', :v => '0', :keyname => '帯出可', :started_at => '1900/1/1')
    end
    add_column :items, :circulation_restriction_id, :integer
    Item.update_all("circulation_restriction_id = #{keycode.id}") if Item.exists?
    change_column :items, :circulation_restriction_id, :integer, :null => false # , :default => keycode.id
    puts "このあとに keycodes fixture をロードすると Keycode.where(:name => 'item.circulation_restriction', :v => '0', :keyname => 帯出可) が重複する可能性があります。確認してください。"
  end
end
