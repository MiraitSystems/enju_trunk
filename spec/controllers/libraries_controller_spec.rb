require 'spec_helper'

describe LibrariesController do
  fixtures :all

  describe "GET index", :solr => true do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all libraries as @libraries" do
        get :index
        assigns(:libraries).should_not be_empty
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all libraries as @libraries" do
        get :index
        assigns(:libraries).should_not be_empty
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all libraries as @libraries" do
        get :index
        assigns(:libraries).should_not be_empty
      end
    end

    describe "When not logged in" do
      it "assigns all libraries as @libraries" do
        get :index
        assigns(:libraries).should_not be_empty
      end

      it "should get index with query" do
        get :index, :query => 'kamata'
        response.should be_success
        assigns(:libraries).include?(Library.find('kamata')).should be_true
      end
    end
  end

  describe "GET show", :solr => true do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested library as @library" do
        get :show, :id => 1
        assigns(:library).should eq(libraries(:library_00001))
      end

      it "assigns nil as @library if id is missing" do
        get :show, :id => 'missing'
        assigns(:library).should be_nil
        response.should be_missing
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested library as @library" do
        get :show, :id => 1
        assigns(:library).should eq(libraries(:library_00001))
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested library as @library" do
        get :show, :id => 1
        assigns(:library).should eq(libraries(:library_00001))
      end
    end

    describe "When not logged in" do
      it "assigns the requested library as @library" do
        get :show, :id => 1
        assigns(:library).should eq(libraries(:library_00001))
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested library as @library" do
        get :new
        assigns(:library).should_not be_valid
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested library as @library" do
        get :new
        assigns(:library).should_not be_valid
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested library as @library" do
        get :new
        assigns(:library).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested library as @library" do
        get :new
        assigns(:library).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested library as @library" do
        library = FactoryGirl.create(:library)
        get :edit, :id => library.id
        assigns(:library).should eq(library)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested library as @library" do
        library = FactoryGirl.create(:library)
        get :edit, :id => library.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested library as @library" do
        library = FactoryGirl.create(:library)
        get :edit, :id => library.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested library as @library" do
        library = FactoryGirl.create(:library)
        get :edit, :id => library.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:library)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created library as @library" do
          post :create, :library => @attrs
          assigns(:library).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :library => @attrs
          response.should redirect_to(assigns(:library))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved library as @library" do
          post :create, :library => @invalid_attrs
          assigns(:library).should_not be_valid
        end

        it "should be successful" do
          post :create, :library => @invalid_attrs
          response.should be_success
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created library as @library" do
          post :create, :library => @attrs
          assigns(:library).should be_valid
        end

        it "should be forbidden" do
          post :create, :library => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved library as @library" do
          post :create, :library => @invalid_attrs
          assigns(:library).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :library => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created library as @library" do
          post :create, :library => @attrs
          assigns(:library).should be_valid
        end

        it "should be forbidden" do
          post :create, :library => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved library as @library" do
          post :create, :library => @invalid_attrs
          assigns(:library).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :library => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created library as @library" do
          post :create, :library => @attrs
          assigns(:library).should be_valid
        end

        it "should be redirected to new session url" do
          post :create, :library => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved library as @library" do
          post :create, :library => @invalid_attrs
          assigns(:library).should_not be_valid
        end

        it "should be redirected to new session url" do
          post :create, :library => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @library = libraries(:library_00001)
      @attrs = {:name => 'example'}
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested library" do
          put :update, :id => @library.id, :library => @attrs
        end

        it "assigns the requested library as @library" do
          put :update, :id => @library.id, :library => @attrs
          assigns(:library).should eq(@library)
        end

        it "moves its position when specified" do
          put :update, :id => @library.id, :library => @attrs, :position => 2
          response.should redirect_to(libraries_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested library as @library" do
          put :update, :id => @library.id, :library => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "updates the requested library" do
          put :update, :id => @library.id, :library => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @library.id, :library => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "should be forbidden" do
          put :update, :id => @library.id, :library => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested library" do
          put :update, :id => @library.id, :library => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @library.id, :library => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "should be forbidden" do
          put :update, :id => @library.id, :library => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested library" do
          put :update, :id => @library.id, :library => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @library.id, :library => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested library as @library" do
          put :update, :id => @library.id, :library => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    describe "Web" do
      before(:each) do
        @library = libraries(:library_00001)
      end

      describe "When logged in as Administrator" do
        before(:each) do
          sign_in FactoryGirl.create(:admin)
        end

        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should be_forbidden
        end
      end

      describe "When logged in as Librarian" do
        before(:each) do
          sign_in FactoryGirl.create(:librarian)
        end

        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should be_forbidden
        end
      end

      describe "When logged in as User" do
        before(:each) do
          sign_in FactoryGirl.create(:user)
        end

        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should be_forbidden
        end
      end

      describe "When not logged in" do
        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should redirect_to(new_user_session_url)
        end
      end
    end

    describe "Library" do
      before(:each) do
        @library = FactoryGirl.create(:library)
        @library.shelves.first.destroy
      end

      describe "When logged in as Administrator" do
        before(:each) do
          sign_in FactoryGirl.create(:admin)
        end

        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "redirects to the libraries list" do
          delete :destroy, :id => @library.id
          response.should redirect_to(libraries_url)
        end
      end

      describe "When logged in as Librarian" do
        before(:each) do
          sign_in FactoryGirl.create(:librarian)
        end

        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should be_forbidden
        end
      end

      describe "When logged in as User" do
        before(:each) do
          sign_in FactoryGirl.create(:user)
        end

        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should be_forbidden
        end
      end

      describe "When not logged in" do
        it "destroys the requested library" do
          delete :destroy, :id => @library.id
        end

        it "should be forbidden" do
          delete :destroy, :id => @library.id
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end
end
