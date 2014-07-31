class DropExemplifies < ActiveRecord::Migration
  def change
    # copy Exemplify#manifestation_id to Item#manifestation_id
    ActiveRecord::Base.connection.send(:select, 'select * from exemplifies').each do |e|
      ActiveRecord::Base.connection.update("update items set manifestation_id = #{e['manifestation_id']} where id = #{e['item_id']}")
    end
    change_column :items, :manifestation_id, :integer, :null => false
    drop_table :exemplifies
  end
end
