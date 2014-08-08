class ChangeColumnVolumeNumberAndIssueNumber < ActiveRecord::Migration
  def change
    change_column :manifestations, :volume_number, :integer, :limit => 8
    change_column :manifestations, :issue_number, :integer, :limit => 8
  end

end
