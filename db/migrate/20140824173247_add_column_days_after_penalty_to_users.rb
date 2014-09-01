class AddColumnDaysAfterPenaltyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :days_after_penalty, :integer, :default => 0
    add_column :users, :in_penalty, :boolean, :default => false
  end
end
