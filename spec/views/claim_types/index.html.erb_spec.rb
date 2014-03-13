require 'spec_helper'

describe "claim_types/index" do
  before(:each) do
    assign(:claim_types, [
      stub_model(ClaimType,
        :name => "Name",
        :display_name => "Display Name"
      ),
      stub_model(ClaimType,
        :name => "Name",
        :display_name => "Display Name"
      )
    ])
  end

  it "renders a list of claim_types" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Display Name".to_s, :count => 2
  end
end
