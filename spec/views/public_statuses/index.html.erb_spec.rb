require 'spec_helper'

describe "public_statuses/index" do
  before(:each) do
    assign(:public_statuses, [
      stub_model(PublicStatus,
        :id => 1,
        :name => "Name",
        :diplay_name => "Diplay Name",
        :note => "MyText"
      ),
      stub_model(PublicStatus,
        :id => 1,
        :name => "Name",
        :diplay_name => "Diplay Name",
        :note => "MyText"
      )
    ])
  end

  it "renders a list of public_statuses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Diplay Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
