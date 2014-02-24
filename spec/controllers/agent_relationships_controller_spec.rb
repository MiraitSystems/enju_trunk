require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe AgentRelationshipsController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    before(:each) do
      FactoryGirl.create(:agent_relationship)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all agent_relationships as @agent_relationships" do
        get :index
        assigns(:agent_relationships).should eq(AgentRelationship.all)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all agent_relationships as @agent_relationships" do
        get :index
        assigns(:agent_relationships).should eq(AgentRelationship.all)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all agent_relationships as @agent_relationships" do
        get :index
        assigns(:agent_relationships).should eq(AgentRelationship.all)
      end
    end

    describe "When not logged in" do
      it "assigns all agent_relationships as @agent_relationships" do
        get :index
        assigns(:agent_relationships).should eq(AgentRelationship.all)
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :show, :id => agent_relationship.id
        assigns(:agent_relationship).should eq(agent_relationship)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :show, :id => agent_relationship.id
        assigns(:agent_relationship).should eq(agent_relationship)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :show, :id => agent_relationship.id
        assigns(:agent_relationship).should eq(agent_relationship)
      end
    end

    describe "When not logged in" do
      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :show, :id => agent_relationship.id
        assigns(:agent_relationship).should eq(agent_relationship)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        get :new
        assigns(:agent_relationship).should_not be_valid
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "should not assign the requested agent_relationship as @agent_relationship" do
        get :new
        assigns(:agent_relationship).should_not be_valid
        response.should be_success
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested agent_relationship as @agent_relationship" do
        get :new
        assigns(:agent_relationship).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent_relationship as @agent_relationship" do
        get :new
        assigns(:agent_relationship).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :edit, :id => agent_relationship.id
        assigns(:agent_relationship).should eq(agent_relationship)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :edit, :id => agent_relationship.id
        assigns(:agent_relationship).should eq(agent_relationship)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :edit, :id => agent_relationship.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent_relationship as @agent_relationship" do
        agent_relationship = FactoryGirl.create(:agent_relationship)
        get :edit, :id => agent_relationship.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:agent_relationship)
      @invalid_attrs = {:parent_id => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @attrs
          assigns(:agent_relationship).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :agent_relationship => @attrs
          response.should redirect_to(assigns(:agent_relationship))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @invalid_attrs
          assigns(:agent_relationship).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :agent_relationship => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @attrs
          assigns(:agent_relationship).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :agent_relationship => @attrs
          response.should redirect_to(assigns(:agent_relationship))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @invalid_attrs
          assigns(:agent_relationship).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :agent_relationship => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @attrs
          assigns(:agent_relationship).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent_relationship => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @invalid_attrs
          assigns(:agent_relationship).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent_relationship => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @attrs
          assigns(:agent_relationship).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent_relationship => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_relationship as @agent_relationship" do
          post :create, :agent_relationship => @invalid_attrs
          assigns(:agent_relationship).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent_relationship => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @agent_relationship = FactoryGirl.create(:agent_relationship)
      @attrs = FactoryGirl.attributes_for(:agent_relationship)
      @invalid_attrs = {:parent_id => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
        end

        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
          assigns(:agent_relationship).should eq(@agent_relationship)
          response.should redirect_to(@agent_relationship)
        end

        it "moves its position when specified" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs, :position => 2
          response.should redirect_to(agent_relationships_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "updates the requested agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
        end

        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
          assigns(:agent_relationship).should eq(@agent_relationship)
          response.should redirect_to(@agent_relationship)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
        end

        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
          assigns(:agent_relationship).should eq(@agent_relationship)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_relationship as @agent_relationship" do
          put :update, :id => @agent_relationship.id, :agent_relationship => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @agent_relationship = FactoryGirl.create(:agent_relationship)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested agent_relationship" do
        delete :destroy, :id => @agent_relationship.id
      end

      it "redirects to the agent_relationships list" do
        delete :destroy, :id => @agent_relationship.id
        response.should redirect_to(agent_relationships_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested agent_relationship" do
        delete :destroy, :id => @agent_relationship.id
      end

      it "redirects to the agent_relationships list" do
        delete :destroy, :id => @agent_relationship.id
        response.should redirect_to(agent_relationships_url)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested agent_relationship" do
        delete :destroy, :id => @agent_relationship.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent_relationship.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested agent_relationship" do
        delete :destroy, :id => @agent_relationship.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent_relationship.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
