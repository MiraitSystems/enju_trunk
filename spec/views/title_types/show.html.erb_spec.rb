require 'spec_helper'

describe "title_types/show" do
  before(:each) do
    @title_type = assign(:title_type, stub_model(TitleType,
      :id => 1,
      :name => "Name",
      :display_name => "MyText",
      :note => "MyText",
      :position => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Name/)
    rendered.should match(/MyText/)
    rendered.should match(/MyText/)
    rendered.should match(/2/)
  end
end
