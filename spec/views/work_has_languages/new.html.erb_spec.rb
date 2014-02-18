require 'spec_helper'

describe "work_has_languages/new" do
  before(:each) do
    assign(:work_has_language, stub_model(WorkHasLanguage,
      :work_id => 1,
      :language_id => 1,
      :position => 1
    ).as_new_record)
  end

  it "renders new work_has_language form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", work_has_languages_path, "post" do
      assert_select "input#work_has_language_work_id[name=?]", "work_has_language[work_id]"
      assert_select "input#work_has_language_language_id[name=?]", "work_has_language[language_id]"
      assert_select "input#work_has_language_position[name=?]", "work_has_language[position]"
    end
  end
end
