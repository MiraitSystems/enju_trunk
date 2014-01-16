require 'spec_helper'

describe "keycodes/index" do
  before(:each) do
    assign(:keycodes, [
      stub_model(Keycode,
        :name => "Name",
        :display_name => "Display Name",
        :v => 1,
        :keyname => "Keyname"
      ),
      stub_model(Keycode,
        :name => "Name",
        :display_name => "Display Name",
        :v => 1,
        :keyname => "Keyname"
      )
    ])
  end

  it "renders a list of keycodes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Display Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Keyname".to_s, :count => 2
  end
end
