require 'spec_helper'

describe "keycodes/show" do
  before(:each) do
    @keycode = assign(:keycode, stub_model(Keycode,
      :name => "Name",
      :display_name => "Display Name",
      :v => 1,
      :keyname => "Keyname"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Display Name/)
    rendered.should match(/1/)
    rendered.should match(/Keyname/)
  end
end
