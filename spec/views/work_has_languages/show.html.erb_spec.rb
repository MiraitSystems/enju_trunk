require 'spec_helper'

describe "work_has_languages/show" do
  before(:each) do
    @work_has_language = assign(:work_has_language, stub_model(WorkHasLanguage,
      :work_id => 1,
      :language_id => 2,
      :position => 3
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/3/)
  end
end
