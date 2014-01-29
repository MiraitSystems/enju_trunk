require "spec_helper"

describe ApprovalExtextsController do
  describe "routing" do

    it "routes to #index" do
      get("/approval_extexts").should route_to("approval_extexts#index")
    end

    it "routes to #new" do
      get("/approval_extexts/new").should route_to("approval_extexts#new")
    end

    it "routes to #show" do
      get("/approval_extexts/1").should route_to("approval_extexts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/approval_extexts/1/edit").should route_to("approval_extexts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/approval_extexts").should route_to("approval_extexts#create")
    end

    it "routes to #update" do
      put("/approval_extexts/1").should route_to("approval_extexts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/approval_extexts/1").should route_to("approval_extexts#destroy", :id => "1")
    end

  end
end
