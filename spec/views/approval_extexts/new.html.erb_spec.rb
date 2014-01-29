require 'spec_helper'

describe "approval_extexts/new" do
  before(:each) do
    assign(:approval_extext, stub_model(ApprovalExtext,
      :name => "MyString",
      :value => "MyText",
      :approval_id => 1,
      :position => 1
    ).as_new_record)
  end

  it "renders new approval_extext form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", approval_extexts_path, "post" do
      assert_select "input#approval_extext_name[name=?]", "approval_extext[name]"
      assert_select "textarea#approval_extext_value[name=?]", "approval_extext[value]"
      assert_select "input#approval_extext_approval_id[name=?]", "approval_extext[approval_id]"
      assert_select "input#approval_extext_position[name=?]", "approval_extext[position]"
    end
  end
end
