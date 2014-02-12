require "spec_helper"

describe TitleTypesController do
  describe "routing" do

    it "routes to #index" do
      get("/title_types").should route_to("title_types#index")
    end

    it "routes to #new" do
      get("/title_types/new").should route_to("title_types#new")
    end

    it "routes to #show" do
      get("/title_types/1").should route_to("title_types#show", :id => "1")
    end

    it "routes to #edit" do
      get("/title_types/1/edit").should route_to("title_types#edit", :id => "1")
    end

    it "routes to #create" do
      post("/title_types").should route_to("title_types#create")
    end

    it "routes to #update" do
      put("/title_types/1").should route_to("title_types#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/title_types/1").should route_to("title_types#destroy", :id => "1")
    end

  end
end
