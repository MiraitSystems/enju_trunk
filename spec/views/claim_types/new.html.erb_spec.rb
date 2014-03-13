require 'spec_helper'

describe "claim_types/new" do
  before(:each) do
    assign(:claim_type, stub_model(ClaimType,
      :name => "MyString",
      :display_name => "MyString"
    ).as_new_record)
  end

  it "renders new claim_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", claim_types_path, "post" do
      assert_select "input#claim_type_name[name=?]", "claim_type[name]"
      assert_select "input#claim_type_display_name[name=?]", "claim_type[display_name]"
    end
  end
end
