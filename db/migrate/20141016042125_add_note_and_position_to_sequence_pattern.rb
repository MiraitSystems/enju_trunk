class AddNoteAndPositionToSequencePattern < ActiveRecord::Migration
  def change
    rename_column :sequence_patterns, :sequence_type, :issue_sequence_type
    rename_column :sequence_patterns, :volume_param, :issue_sequence_param
    add_column :sequence_patterns, :reset_issue_param, :boolean, :default => true
    add_column :sequence_patterns, :volume_param, :integer
    add_column :sequence_patterns, :volume_sequence_type, :integer
    add_column :sequence_patterns, :note, :text
    add_column :sequence_patterns, :description, :text
    add_column :sequence_patterns, :display, :boolean, :default => true
    add_column :sequence_patterns, :position, :integer
  end
end
