class AddIndexToFunctions < ActiveRecord::Migration
  def change
    add_index :functions, :controller_name, :name => 'functions_controller_name_index'
  end
end
