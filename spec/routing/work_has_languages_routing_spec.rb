require "spec_helper"

describe WorkHasLanguagesController do
  describe "routing" do

    it "routes to #index" do
      get("/work_has_languages").should route_to("work_has_languages#index")
    end

    it "routes to #new" do
      get("/work_has_languages/new").should route_to("work_has_languages#new")
    end

    it "routes to #show" do
      get("/work_has_languages/1").should route_to("work_has_languages#show", :id => "1")
    end

    it "routes to #edit" do
      get("/work_has_languages/1/edit").should route_to("work_has_languages#edit", :id => "1")
    end

    it "routes to #create" do
      post("/work_has_languages").should route_to("work_has_languages#create")
    end

    it "routes to #update" do
      put("/work_has_languages/1").should route_to("work_has_languages#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/work_has_languages/1").should route_to("work_has_languages#destroy", :id => "1")
    end

  end
end
