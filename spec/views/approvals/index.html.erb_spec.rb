require 'spec_helper'

describe "approvals/index" do
  before(:each) do
    assign(:approvals, [
      stub_model(Approval,
        :id => 1,
        :manifestation_id => 2,
        :created_by => 3,
        :collect_user => "Collect User",
        :status => "Status",
        :publication_status => 4,
        :sample_carrier_type => 5,
        :sample_name => "Sample Name",
        :sample_note => "MyText",
        :group_user_id => 6,
        :group_approval_result => 7,
        :group_result_reason => 8,
        :group_note => "MyText",
        :adoption_report_flg => false,
        :approval_result => 9,
        :reason => 10,
        :donate_request_result => 11,
        :reception_agent_id => 12
      ),
      stub_model(Approval,
        :id => 1,
        :manifestation_id => 2,
        :created_by => 3,
        :collect_user => "Collect User",
        :status => "Status",
        :publication_status => 4,
        :sample_carrier_type => 5,
        :sample_name => "Sample Name",
        :sample_note => "MyText",
        :group_user_id => 6,
        :group_approval_result => 7,
        :group_result_reason => 8,
        :group_note => "MyText",
        :adoption_report_flg => false,
        :approval_result => 9,
        :reason => 10,
        :donate_request_result => 11,
        :reception_agent_id => 12
      )
    ])
  end

  it "renders a list of approvals" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "Collect User".to_s, :count => 2
    assert_select "tr>td", :text => "Status".to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
    assert_select "tr>td", :text => 5.to_s, :count => 2
    assert_select "tr>td", :text => "Sample Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 6.to_s, :count => 2
    assert_select "tr>td", :text => 7.to_s, :count => 2
    assert_select "tr>td", :text => 8.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => 9.to_s, :count => 2
    assert_select "tr>td", :text => 10.to_s, :count => 2
    assert_select "tr>td", :text => 11.to_s, :count => 2
    assert_select "tr>td", :text => 12.to_s, :count => 2
  end
end
