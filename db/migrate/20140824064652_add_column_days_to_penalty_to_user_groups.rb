class AddColumnDaysToPenaltyToUserGroups < ActiveRecord::Migration
  def change
    add_column :user_groups, :auto_mode, :boolean, :default => true, :null => false
    add_column :user_groups, :days_to_penalty, :integer, :default => 1
    add_column :user_groups, :restrict_reservation_in_penalty, :boolean, :default => false
    add_column :user_groups, :restrict_recheckout_in_penalty, :boolean, :default => true
    add_column :user_groups, :restrict_checkout_in_penalty, :integer, :default => 2
    add_column :user_groups, :restrict_checkout_after_penalty, :integer, :default => 0
    add_column :user_groups, :checkout_limit_after_penalty_in_probation, :integer, :default => 1
  end
end
