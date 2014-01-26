class CreateApprovals < ActiveRecord::Migration
  def change
    create_table :approvals do |t|
      t.integer :id
      t.integer :manifestation_id
      t.timestamp :created_at
      t.timestamp :updated_at
      t.integer :created_by
      t.string :collect_user
      t.timestamp :all_process_start_at
      t.string :status
      t.integer :publication_status
      t.timestamp :sample_request_at
      t.timestamp :sample_arrival_at
      t.integer :sample_carrier_type
      t.string :sample_name
      t.text :sample_note
      t.integer :group_user_id
      t.timestamp :group_approval_at
      t.integer :group_approval_result
      t.integer :group_result_reason
      t.text :group_note
      t.boolean :adoption_report_flg
      t.integer :approval_result
      t.integer :reason
      t.timestamp :approval_end_at
      t.timestamp :donate_request_at
      t.timestamp :donate_request_replay_at
      t.timestamp :refuse_at
      t.integer :donate_request_result
      t.timestamp :all_process_end_at
      t.integer :reception_patron_id

      t.timestamps
    end
  end
end
