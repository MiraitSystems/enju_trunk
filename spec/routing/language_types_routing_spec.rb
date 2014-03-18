require "spec_helper"

describe LanguageTypesController do
  describe "routing" do

    it "routes to #index" do
      get("/language_types").should route_to("language_types#index")
    end

    it "routes to #new" do
      get("/language_types/new").should route_to("language_types#new")
    end

    it "routes to #show" do
      get("/language_types/1").should route_to("language_types#show", :id => "1")
    end

    it "routes to #edit" do
      get("/language_types/1/edit").should route_to("language_types#edit", :id => "1")
    end

    it "routes to #create" do
      post("/language_types").should route_to("language_types#create")
    end

    it "routes to #update" do
      put("/language_types/1").should route_to("language_types#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/language_types/1").should route_to("language_types#destroy", :id => "1")
    end

  end
end
