require 'spec_helper'

describe "public_statuses/show" do
  before(:each) do
    @public_status = assign(:public_status, stub_model(PublicStatus,
      :id => 1,
      :name => "Name",
      :diplay_name => "Diplay Name",
      :note => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Name/)
    rendered.should match(/Diplay Name/)
    rendered.should match(/MyText/)
  end
end
