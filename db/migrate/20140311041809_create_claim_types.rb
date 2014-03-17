class CreateClaimTypes < ActiveRecord::Migration
  def change
    create_table :claim_types do |t|
      t.string :name
      t.string :display_name

      t.timestamps
    end
  end
end
