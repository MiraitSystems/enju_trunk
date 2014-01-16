require "spec_helper"

describe KeycodesController do
  describe "routing" do

    it "routes to #index" do
      get("/keycodes").should route_to("keycodes#index")
    end

    it "routes to #new" do
      get("/keycodes/new").should route_to("keycodes#new")
    end

    it "routes to #show" do
      get("/keycodes/1").should route_to("keycodes#show", :id => "1")
    end

    it "routes to #edit" do
      get("/keycodes/1/edit").should route_to("keycodes#edit", :id => "1")
    end

    it "routes to #create" do
      post("/keycodes").should route_to("keycodes#create")
    end

    it "routes to #update" do
      put("/keycodes/1").should route_to("keycodes#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/keycodes/1").should route_to("keycodes#destroy", :id => "1")
    end

  end
end
