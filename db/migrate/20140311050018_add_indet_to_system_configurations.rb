class AddIndetToSystemConfigurations < ActiveRecord::Migration
  def change
    add_index :system_configurations, :v, :name => 'v_system_configurations'
    add_index :system_configurations, :keyname, :name => 'keyname_system_configurations'
  end
end
