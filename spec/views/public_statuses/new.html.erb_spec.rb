require 'spec_helper'

describe "public_statuses/new" do
  before(:each) do
    assign(:public_status, stub_model(PublicStatus,
      :id => 1,
      :name => "MyString",
      :diplay_name => "MyString",
      :note => "MyText"
    ).as_new_record)
  end

  it "renders new public_status form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", public_statuses_path, "post" do
      assert_select "input#public_status_id[name=?]", "public_status[id]"
      assert_select "input#public_status_name[name=?]", "public_status[name]"
      assert_select "input#public_status_diplay_name[name=?]", "public_status[diplay_name]"
      assert_select "textarea#public_status_note[name=?]", "public_status[note]"
    end
  end
end
