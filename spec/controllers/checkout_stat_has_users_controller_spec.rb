require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe CheckoutStatHasUsersController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    before(:each) do
      FactoryGirl.create(:checkout_stat_has_user)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all checkout_stat_has_users as @checkout_stat_has_users" do
        get :index
        assigns(:checkout_stat_has_users).should eq(CheckoutStatHasUser.all)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all checkout_stat_has_users as @checkout_stat_has_users" do
        get :index
        assigns(:checkout_stat_has_users).should eq(CheckoutStatHasUser.all)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all checkout_stat_has_users as @checkout_stat_has_users" do
        get :index
        assigns(:checkout_stat_has_users).should be_empty
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "assigns all checkout_stat_has_users as @checkout_stat_has_users" do
        get :index
        assigns(:checkout_stat_has_users).should be_empty
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :show, :id => checkout_stat_has_user.id
        assigns(:checkout_stat_has_user).should eq(checkout_stat_has_user)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :show, :id => checkout_stat_has_user.id
        assigns(:checkout_stat_has_user).should eq(checkout_stat_has_user)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :show, :id => checkout_stat_has_user.id
        assigns(:checkout_stat_has_user).should eq(checkout_stat_has_user)
      end
    end

    describe "When not logged in" do
      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :show, :id => checkout_stat_has_user.id
        assigns(:checkout_stat_has_user).should eq(checkout_stat_has_user)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        get :new
        assigns(:checkout_stat_has_user).should_not be_valid
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "should not assign the requested checkout_stat_has_user as @checkout_stat_has_user" do
        get :new
        assigns(:checkout_stat_has_user).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested checkout_stat_has_user as @checkout_stat_has_user" do
        get :new
        assigns(:checkout_stat_has_user).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested checkout_stat_has_user as @checkout_stat_has_user" do
        get :new
        assigns(:checkout_stat_has_user).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :edit, :id => checkout_stat_has_user.id
        assigns(:checkout_stat_has_user).should eq(checkout_stat_has_user)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :edit, :id => checkout_stat_has_user.id
        assigns(:checkout_stat_has_user).should eq(checkout_stat_has_user)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :edit, :id => checkout_stat_has_user.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested checkout_stat_has_user as @checkout_stat_has_user" do
        checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
        get :edit, :id => checkout_stat_has_user.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:checkout_stat_has_user)
      @invalid_attrs = {:user_checkout_stat_id => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @attrs
          assigns(:checkout_stat_has_user).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :checkout_stat_has_user => @attrs
          response.should redirect_to(assigns(:checkout_stat_has_user))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          assigns(:checkout_stat_has_user).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @attrs
          assigns(:checkout_stat_has_user).should be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_stat_has_user => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          assigns(:checkout_stat_has_user).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @attrs
          assigns(:checkout_stat_has_user).should be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_stat_has_user => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          assigns(:checkout_stat_has_user).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @attrs
          assigns(:checkout_stat_has_user).should be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_stat_has_user => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_stat_has_user as @checkout_stat_has_user" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          assigns(:checkout_stat_has_user).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_stat_has_user => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
      @attrs = FactoryGirl.attributes_for(:checkout_stat_has_user)
      @invalid_attrs = {:user_checkout_stat_id => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
        end

        it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
          assigns(:checkout_stat_has_user).should eq(@checkout_stat_has_user)
          response.should redirect_to(@checkout_stat_has_user)
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @invalid_attrs
          assigns(:checkout_stat_has_user).should eq(@checkout_stat_has_user)
        end

        it "should be forbidden" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
          assigns(:checkout_stat_has_user).should eq(@checkout_stat_has_user)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_stat_has_user as @checkout_stat_has_user" do
          put :update, :id => @checkout_stat_has_user.id, :checkout_stat_has_user => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @checkout_stat_has_user = FactoryGirl.create(:checkout_stat_has_user)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested checkout_stat_has_user" do
        delete :destroy, :id => @checkout_stat_has_user.id
      end

      it "redirects to the checkout_stat_has_users list" do
        delete :destroy, :id => @checkout_stat_has_user.id
        response.should redirect_to(checkout_stat_has_users_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested checkout_stat_has_user" do
        delete :destroy, :id => @checkout_stat_has_user.id
      end

      it "redirects to the checkout_stat_has_users list" do
        delete :destroy, :id => @checkout_stat_has_user.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested checkout_stat_has_user" do
        delete :destroy, :id => @checkout_stat_has_user.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @checkout_stat_has_user.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested checkout_stat_has_user" do
        delete :destroy, :id => @checkout_stat_has_user.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @checkout_stat_has_user.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
