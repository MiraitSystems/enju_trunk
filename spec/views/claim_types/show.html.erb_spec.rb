require 'spec_helper'

describe "claim_types/show" do
  before(:each) do
    @claim_type = assign(:claim_type, stub_model(ClaimType,
      :name => "Name",
      :display_name => "Display Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Display Name/)
  end
end
