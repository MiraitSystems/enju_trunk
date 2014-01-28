require 'spec_helper'

describe "approval_extexts/show" do
  before(:each) do
    @approval_extext = assign(:approval_extext, stub_model(ApprovalExtext,
      :name => "Name",
      :value => "MyText",
      :approval_id => 1,
      :position => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/MyText/)
    rendered.should match(/1/)
    rendered.should match(/2/)
  end
end
