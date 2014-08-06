class DropClassmarks < ActiveRecord::Migration
  def change
    drop_table :classmarks
  end

end
