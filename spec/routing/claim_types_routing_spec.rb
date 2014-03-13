require "spec_helper"

describe ClaimTypesController do
  describe "routing" do

    it "routes to #index" do
      get("/claim_types").should route_to("claim_types#index")
    end

    it "routes to #new" do
      get("/claim_types/new").should route_to("claim_types#new")
    end

    it "routes to #show" do
      get("/claim_types/1").should route_to("claim_types#show", :id => "1")
    end

    it "routes to #edit" do
      get("/claim_types/1/edit").should route_to("claim_types#edit", :id => "1")
    end

    it "routes to #create" do
      post("/claim_types").should route_to("claim_types#create")
    end

    it "routes to #update" do
      put("/claim_types/1").should route_to("claim_types#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/claim_types/1").should route_to("claim_types#destroy", :id => "1")
    end

  end
end
