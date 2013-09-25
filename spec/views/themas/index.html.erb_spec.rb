require 'spec_helper'

describe "themas/index" do
  before(:each) do
    assign(:themas, [
      stub_model(Thema,
        :name => "Name",
        :description => "MyText",
        :publish => 1,
        :note => "MyText",
        :position => 2
      ),
      stub_model(Thema,
        :name => "Name",
        :description => "MyText",
        :publish => 1,
        :note => "MyText",
        :position => 2
      )
    ])
  end

  it "renders a list of themas" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
