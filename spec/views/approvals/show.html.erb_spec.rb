require 'spec_helper'

describe "approvals/show" do
  before(:each) do
    @approval = assign(:approval, stub_model(Approval,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/3/)
    rendered.should match(/Collect User/)
    rendered.should match(/Status/)
    rendered.should match(/4/)
    rendered.should match(/5/)
    rendered.should match(/Sample Name/)
    rendered.should match(/MyText/)
    rendered.should match(/6/)
    rendered.should match(/7/)
    rendered.should match(/8/)
    rendered.should match(/MyText/)
    rendered.should match(/false/)
    rendered.should match(/9/)
    rendered.should match(/10/)
    rendered.should match(/11/)
    rendered.should match(/12/)
  end
end
