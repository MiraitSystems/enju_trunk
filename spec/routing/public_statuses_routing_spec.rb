require "spec_helper"

describe PublicStatusesController do
  describe "routing" do

    it "routes to #index" do
      get("/public_statuses").should route_to("public_statuses#index")
    end

    it "routes to #new" do
      get("/public_statuses/new").should route_to("public_statuses#new")
    end

    it "routes to #show" do
      get("/public_statuses/1").should route_to("public_statuses#show", :id => "1")
    end

    it "routes to #edit" do
      get("/public_statuses/1/edit").should route_to("public_statuses#edit", :id => "1")
    end

    it "routes to #create" do
      post("/public_statuses").should route_to("public_statuses#create")
    end

    it "routes to #update" do
      put("/public_statuses/1").should route_to("public_statuses#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/public_statuses/1").should route_to("public_statuses#destroy", :id => "1")
    end

  end
end
