class CreateUseLicenses < ActiveRecord::Migration
  def change
    create_table :use_licenses do |t|
      t.integer :id
      t.integer :target
      t.integer :author
      t.boolean :author_fee
      t.string :agency_name
      t.string :agency_address
      t.string :responsible_name
      t.string :responsible_tel
      t.string :responsible_mail
      t.string :bank_name
      t.string :bank_code
      t.string :branch_name
      t.string :branch_number
      t.string :account_name
      t.string :account_number
      t.integer :account_kind

      t.timestamps
    end
  end
end
