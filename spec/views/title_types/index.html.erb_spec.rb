require 'spec_helper'

describe "title_types/index" do
  before(:each) do
    assign(:title_types, [
      stub_model(TitleType,
        :id => 1,
        :name => "Name",
        :display_name => "MyText",
        :note => "MyText",
        :position => 2
      ),
      stub_model(TitleType,
        :id => 1,
        :name => "Name",
        :display_name => "MyText",
        :note => "MyText",
        :position => 2
      )
    ])
  end

  it "renders a list of title_types" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
