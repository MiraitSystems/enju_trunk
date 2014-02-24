require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe CheckoutTypesController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    before(:each) do
      FactoryGirl.create(:checkout_type)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all checkout_types as @checkout_types" do
        get :index
        assigns(:checkout_types).should eq(CheckoutType.all)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all checkout_types as @checkout_types" do
        get :index
        assigns(:checkout_types).should eq(CheckoutType.all)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all checkout_types as @checkout_types" do
        get :index
        assigns(:checkout_types).should be_empty
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "assigns all checkout_types as @checkout_types" do
        get :index
        assigns(:checkout_types).should be_empty
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :show, :id => checkout_type.id
        assigns(:checkout_type).should eq(checkout_type)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :show, :id => checkout_type.id
        assigns(:checkout_type).should eq(checkout_type)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :show, :id => checkout_type.id
        assigns(:checkout_type).should eq(checkout_type)
      end
    end

    describe "When not logged in" do
      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :show, :id => checkout_type.id
        assigns(:checkout_type).should eq(checkout_type)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        get :new
        assigns(:checkout_type).should_not be_valid
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "should not assign the requested checkout_type as @checkout_type" do
        get :new
        assigns(:checkout_type).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested checkout_type as @checkout_type" do
        get :new
        assigns(:checkout_type).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested checkout_type as @checkout_type" do
        get :new
        assigns(:checkout_type).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :edit, :id => checkout_type.id
        assigns(:checkout_type).should eq(checkout_type)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :edit, :id => checkout_type.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :edit, :id => checkout_type.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested checkout_type as @checkout_type" do
        checkout_type = FactoryGirl.create(:checkout_type)
        get :edit, :id => checkout_type.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:checkout_type)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created checkout_type as @checkout_type" do
          post :create, :checkout_type => @attrs
          assigns(:checkout_type).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :checkout_type => @attrs
          response.should redirect_to(assigns(:checkout_type))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_type as @checkout_type" do
          post :create, :checkout_type => @invalid_attrs
          assigns(:checkout_type).should_not be_valid
        end

        it "should be successful" do
          post :create, :checkout_type => @invalid_attrs
          response.should be_success
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created checkout_type as @checkout_type" do
          post :create, :checkout_type => @attrs
          assigns(:checkout_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_type => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_type as @checkout_type" do
          post :create, :checkout_type => @invalid_attrs
          assigns(:checkout_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created checkout_type as @checkout_type" do
          post :create, :checkout_type => @attrs
          assigns(:checkout_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_type => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_type as @checkout_type" do
          post :create, :checkout_type => @invalid_attrs
          assigns(:checkout_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created checkout_type as @checkout_type" do
          post :create, :checkout_type => @attrs
          assigns(:checkout_type).should be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_type => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved checkout_type as @checkout_type" do
          post :create, :checkout_type => @invalid_attrs
          assigns(:checkout_type).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :checkout_type => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @checkout_type = FactoryGirl.create(:checkout_type)
      @attrs = FactoryGirl.attributes_for(:checkout_type)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
        end

        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
          assigns(:checkout_type).should eq(@checkout_type)
        end

        it "moves its position when specified" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs, :position => 2
          response.should redirect_to(checkout_types_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "updates the requested checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
        end

        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
          assigns(:checkout_type).should eq(@checkout_type)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
        end

        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
          assigns(:checkout_type).should eq(@checkout_type)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @checkout_type.id, :checkout_type => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested checkout_type as @checkout_type" do
          put :update, :id => @checkout_type.id, :checkout_type => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @checkout_type = FactoryGirl.create(:checkout_type)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested checkout_type" do
        delete :destroy, :id => @checkout_type.id
      end

      it "redirects to the checkout_types list" do
        delete :destroy, :id => @checkout_type.id
        response.should redirect_to(checkout_types_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested checkout_type" do
        delete :destroy, :id => @checkout_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @checkout_type.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested checkout_type" do
        delete :destroy, :id => @checkout_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @checkout_type.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested checkout_type" do
        delete :destroy, :id => @checkout_type.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @checkout_type.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
