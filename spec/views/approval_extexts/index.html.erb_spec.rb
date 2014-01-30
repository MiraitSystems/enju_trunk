require 'spec_helper'

describe "approval_extexts/index" do
  before(:each) do
    assign(:approval_extexts, [
      stub_model(ApprovalExtext,
        :name => "Name",
        :value => "MyText",
        :approval_id => 1,
        :position => 2
      ),
      stub_model(ApprovalExtext,
        :name => "Name",
        :value => "MyText",
        :approval_id => 1,
        :position => 2
      )
    ])
  end

  it "renders a list of approval_extexts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
