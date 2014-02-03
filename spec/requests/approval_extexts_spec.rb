require 'spec_helper'

describe "ApprovalExtexts" do
  describe "GET /approval_extexts" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get approval_extexts_path
      response.status.should be(200)
    end
  end
end
