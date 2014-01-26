require 'spec_helper'

describe "approvals/edit" do
  before(:each) do
    @approval = assign(:approval, stub_model(Approval,
      :id => 1,
      :manifestation_id => 1,
      :created_by => 1,
      :collect_user => "MyString",
      :status => "MyString",
      :publication_status => 1,
      :sample_carrier_type => 1,
      :sample_name => "MyString",
      :sample_note => "MyText",
      :group_user_id => 1,
      :group_approval_result => 1,
      :group_result_reason => 1,
      :group_note => "MyText",
      :adoption_report_flg => false,
      :approval_result => 1,
      :reason => 1,
      :donate_request_result => 1,
      :reception_patron_id => 1
    ))
  end

  it "renders the edit approval form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", approval_path(@approval), "post" do
      assert_select "input#approval_id[name=?]", "approval[id]"
      assert_select "input#approval_manifestation_id[name=?]", "approval[manifestation_id]"
      assert_select "input#approval_created_by[name=?]", "approval[created_by]"
      assert_select "input#approval_collect_user[name=?]", "approval[collect_user]"
      assert_select "input#approval_status[name=?]", "approval[status]"
      assert_select "input#approval_publication_status[name=?]", "approval[publication_status]"
      assert_select "input#approval_sample_carrier_type[name=?]", "approval[sample_carrier_type]"
      assert_select "input#approval_sample_name[name=?]", "approval[sample_name]"
      assert_select "textarea#approval_sample_note[name=?]", "approval[sample_note]"
      assert_select "input#approval_group_user_id[name=?]", "approval[group_user_id]"
      assert_select "input#approval_group_approval_result[name=?]", "approval[group_approval_result]"
      assert_select "input#approval_group_result_reason[name=?]", "approval[group_result_reason]"
      assert_select "textarea#approval_group_note[name=?]", "approval[group_note]"
      assert_select "input#approval_adoption_report_flg[name=?]", "approval[adoption_report_flg]"
      assert_select "input#approval_approval_result[name=?]", "approval[approval_result]"
      assert_select "input#approval_reason[name=?]", "approval[reason]"
      assert_select "input#approval_donate_request_result[name=?]", "approval[donate_request_result]"
      assert_select "input#approval_reception_patron_id[name=?]", "approval[reception_patron_id]"
    end
  end
end
