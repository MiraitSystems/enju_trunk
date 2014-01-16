require 'spec_helper'

describe "keycodes/edit" do
  before(:each) do
    @keycode = assign(:keycode, stub_model(Keycode,
      :name => "MyString",
      :display_name => "MyString",
      :v => 1,
      :keyname => "MyString"
    ))
  end

  it "renders the edit keycode form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", keycode_path(@keycode), "post" do
      assert_select "input#keycode_name[name=?]", "keycode[name]"
      assert_select "input#keycode_display_name[name=?]", "keycode[display_name]"
      assert_select "input#keycode_v[name=?]", "keycode[v]"
      assert_select "input#keycode_keyname[name=?]", "keycode[keyname]"
    end
  end
end
