require 'spec_helper'

describe "title_types/edit" do
  before(:each) do
    @title_type = assign(:title_type, stub_model(TitleType,
      :id => 1,
      :name => "MyString",
      :display_name => "MyText",
      :note => "MyText",
      :position => 1
    ))
  end

  it "renders the edit title_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", title_type_path(@title_type), "post" do
      assert_select "input#title_type_id[name=?]", "title_type[id]"
      assert_select "input#title_type_name[name=?]", "title_type[name]"
      assert_select "textarea#title_type_display_name[name=?]", "title_type[display_name]"
      assert_select "textarea#title_type_note[name=?]", "title_type[note]"
      assert_select "input#title_type_position[name=?]", "title_type[position]"
    end
  end
end
