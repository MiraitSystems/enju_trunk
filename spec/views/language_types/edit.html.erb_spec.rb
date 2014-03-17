require 'spec_helper'

describe "language_types/edit" do
  before(:each) do
    @language_type = assign(:language_type, stub_model(LanguageType,
      :name => "MyString",
      :display_name => "MyString",
      :note => "MyString",
      :position => 1
    ))
  end

  it "renders the edit language_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", language_type_path(@language_type), "post" do
      assert_select "input#language_type_name[name=?]", "language_type[name]"
      assert_select "input#language_type_display_name[name=?]", "language_type[display_name]"
      assert_select "input#language_type_note[name=?]", "language_type[note]"
      assert_select "input#language_type_position[name=?]", "language_type[position]"
    end
  end
end
