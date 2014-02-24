require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe SearchEnginesController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    before(:each) do
      FactoryGirl.create(:search_engine)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all search_engines as @search_engines" do
        get :index
        assigns(:search_engines).should eq(SearchEngine.page(1))
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all search_engines as @search_engines" do
        get :index
        assigns(:search_engines).should eq(SearchEngine.page(1))
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all search_engines as @search_engines" do
        get :index
        assigns(:search_engines).should be_empty
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "assigns all search_engines as @search_engines" do
        get :index
        assigns(:search_engines).should be_empty
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :show, :id => search_engine.id
        assigns(:search_engine).should eq(search_engine)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :show, :id => search_engine.id
        assigns(:search_engine).should eq(search_engine)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :show, :id => search_engine.id
        assigns(:search_engine).should eq(search_engine)
      end
    end

    describe "When not logged in" do
      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :show, :id => search_engine.id
        assigns(:search_engine).should eq(search_engine)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested search_engine as @search_engine" do
        get :new
        assigns(:search_engine).should_not be_valid
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "should not assign the requested search_engine as @search_engine" do
        get :new
        assigns(:search_engine).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested search_engine as @search_engine" do
        get :new
        assigns(:search_engine).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested search_engine as @search_engine" do
        get :new
        assigns(:search_engine).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :edit, :id => search_engine.id
        assigns(:search_engine).should eq(search_engine)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :edit, :id => search_engine.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :edit, :id => search_engine.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested search_engine as @search_engine" do
        search_engine = FactoryGirl.create(:search_engine)
        get :edit, :id => search_engine.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:search_engine)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created search_engine as @search_engine" do
          post :create, :search_engine => @attrs
          assigns(:search_engine).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :search_engine => @attrs
          response.should redirect_to(assigns(:search_engine))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved search_engine as @search_engine" do
          post :create, :search_engine => @invalid_attrs
          assigns(:search_engine).should_not be_valid
        end

        it "should be successful" do
          post :create, :search_engine => @invalid_attrs
          response.should be_success
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created search_engine as @search_engine" do
          post :create, :search_engine => @attrs
          assigns(:search_engine).should be_valid
        end

        it "should be forbidden" do
          post :create, :search_engine => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved search_engine as @search_engine" do
          post :create, :search_engine => @invalid_attrs
          assigns(:search_engine).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :search_engine => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created search_engine as @search_engine" do
          post :create, :search_engine => @attrs
          assigns(:search_engine).should be_valid
        end

        it "should be forbidden" do
          post :create, :search_engine => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved search_engine as @search_engine" do
          post :create, :search_engine => @invalid_attrs
          assigns(:search_engine).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :search_engine => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created search_engine as @search_engine" do
          post :create, :search_engine => @attrs
          assigns(:search_engine).should be_valid
        end

        it "should be forbidden" do
          post :create, :search_engine => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved search_engine as @search_engine" do
          post :create, :search_engine => @invalid_attrs
          assigns(:search_engine).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :search_engine => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @search_engine = FactoryGirl.create(:search_engine)
      @attrs = FactoryGirl.attributes_for(:search_engine)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
        end

        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
          assigns(:search_engine).should eq(@search_engine)
        end

        it "moves its position when specified" do
          put :update, :id => @search_engine.id, :search_engine => @attrs, :position => 2
          response.should redirect_to(search_engines_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "updates the requested search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
        end

        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
          assigns(:search_engine).should eq(@search_engine)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
        end

        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
          assigns(:search_engine).should eq(@search_engine)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @search_engine.id, :search_engine => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested search_engine as @search_engine" do
          put :update, :id => @search_engine.id, :search_engine => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @search_engine = FactoryGirl.create(:search_engine)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested search_engine" do
        delete :destroy, :id => @search_engine.id
      end

      it "redirects to the search_engines list" do
        delete :destroy, :id => @search_engine.id
        response.should redirect_to(search_engines_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested search_engine" do
        delete :destroy, :id => @search_engine.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @search_engine.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested search_engine" do
        delete :destroy, :id => @search_engine.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @search_engine.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested search_engine" do
        delete :destroy, :id => @search_engine.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @search_engine.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
