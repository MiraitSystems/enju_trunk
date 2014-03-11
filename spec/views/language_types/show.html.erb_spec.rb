require 'spec_helper'

describe "language_types/show" do
  before(:each) do
    @language_type = assign(:language_type, stub_model(LanguageType,
      :name => "Name",
      :display_name => "Display Name",
      :note => "Note",
      :position => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Display Name/)
    rendered.should match(/Note/)
    rendered.should match(/1/)
  end
end
