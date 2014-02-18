require 'spec_helper'

describe "work_has_languages/index" do
  before(:each) do
    assign(:work_has_languages, [
      stub_model(WorkHasLanguage,
        :work_id => 1,
        :language_id => 2,
        :position => 3
      ),
      stub_model(WorkHasLanguage,
        :work_id => 1,
        :language_id => 2,
        :position => 3
      )
    ])
  end

  it "renders a list of work_has_languages" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
  end
end
