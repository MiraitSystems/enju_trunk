class AddApprovalIdentifierToApprovals < ActiveRecord::Migration
  def change
    add_column :approvals, :approval_identifier, :string
    add_column :approvals, :thrsis_review_flg, :integer
    add_column :approvals, :ja_text_author_summary_flg, :integer
    add_column :approvals, :en_text_author_summary_flg, :integer
    add_column :approvals, :proceedings_number_of_year, :integer
    add_column :approvals, :excepting_number_of_year, :integer
    add_column :approvals, :four_priority_areas, :integer
    add_column :approvals, :document_classification_1, :integer
    add_column :approvals, :document_classification_2, :integer
  end
end
