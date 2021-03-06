require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe AgentTypesController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    before(:each) do
      FactoryGirl.create(:agent_type)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all agent_types as @agent_types" do
        get :index
        assigns(:agent_types).should eq(AgentType.all)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all agent_types as @agent_types" do
        get :index
        assigns(:agent_types).should eq(AgentType.all)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns empty as @agent_types" do
        get :index
        assigns(:agent_types).should be_empty
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "assigns emptry as @agent_types" do
        get :index
        assigns(:agent_types).should be_empty
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :show, :id => agent_type.id
        assigns(:agent_type).should eq(agent_type)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :show, :id => agent_type.id
        assigns(:agent_type).should eq(agent_type)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :show, :id => agent_type.id
        assigns(:agent_type).should eq(agent_type)
      end
    end

    describe "When not logged in" do
      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :show, :id => agent_type.id
        assigns(:agent_type).should eq(agent_type)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent_type as @agent_type" do
        get :new
        assigns(:agent_type).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "should not assign the requested agent_type as @agent_type" do
        get :new
        assigns(:agent_type).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested agent_type as @agent_type" do
        get :new
        assigns(:agent_type).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent_type as @agent_type" do
        get :new
        assigns(:agent_type).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :edit, :id => agent_type.id
        assigns(:agent_type).should eq(agent_type)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :edit, :id => agent_type.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :edit, :id => agent_type.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent_type as @agent_type" do
        agent_type = FactoryGirl.create(:agent_type)
        get :edit, :id => agent_type.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:agent_type)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created agent_type as @agent_type" do
          post :create, :agent_type => @attrs
          assigns(:agent_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_type as @agent_type" do
          post :create, :agent_type => @invalid_attrs
          assigns(:agent_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created agent_type as @agent_type" do
          post :create, :agent_type => @attrs
          assigns(:agent_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_type as @agent_type" do
          post :create, :agent_type => @invalid_attrs
          assigns(:agent_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created agent_type as @agent_type" do
          post :create, :agent_type => @attrs
          assigns(:agent_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_type as @agent_type" do
          post :create, :agent_type => @invalid_attrs
          assigns(:agent_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created agent_type as @agent_type" do
          post :create, :agent_type => @attrs
          assigns(:agent_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent_type as @agent_type" do
          post :create, :agent_type => @invalid_attrs
          assigns(:agent_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent_type => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @agent_type = FactoryGirl.create(:agent_type)
      @attrs = FactoryGirl.attributes_for(:agent_type)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
        end

        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
          assigns(:agent_type).should eq(@agent_type)
        end

        it "moves its position when specified" do
          put :update, :id => @agent_type.id, :agent_type => @attrs, :position => 2
          response.should redirect_to(agent_types_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "updates the requested agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
        end

        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
          assigns(:agent_type).should eq(@agent_type)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
        end

        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
          assigns(:agent_type).should eq(@agent_type)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @agent_type.id, :agent_type => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent_type as @agent_type" do
          put :update, :id => @agent_type.id, :agent_type => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @agent_type = FactoryGirl.create(:agent_type)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested agent_type" do
        delete :destroy, :id => @agent_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent_type.id
        response.should be_forbidden
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested agent_type" do
        delete :destroy, :id => @agent_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent_type.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested agent_type" do
        delete :destroy, :id => @agent_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent_type.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested agent_type" do
        delete :destroy, :id => @agent_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent_type.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
