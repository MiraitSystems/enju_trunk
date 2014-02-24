require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe ItemHasUseRestrictionsController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    before(:each) do
      FactoryGirl.create(:item_has_use_restriction)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all item_has_use_restrictions as @item_has_use_restrictions" do
        get :index
        assigns(:item_has_use_restrictions).should eq(ItemHasUseRestriction.all(:order => 'id DESC'))
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all item_has_use_restrictions as @item_has_use_restrictions" do
        get :index
        assigns(:item_has_use_restrictions).should eq(ItemHasUseRestriction.all(:order => 'id DESC'))
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all item_has_use_restrictions as @item_has_use_restrictions" do
        get :index
        assigns(:item_has_use_restrictions).should be_empty
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "assigns all item_has_use_restrictions as @item_has_use_restrictions" do
        get :index
        assigns(:item_has_use_restrictions).should be_empty
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :show, :id => item_has_use_restriction.id
        assigns(:item_has_use_restriction).should eq(item_has_use_restriction)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :show, :id => item_has_use_restriction.id
        assigns(:item_has_use_restriction).should eq(item_has_use_restriction)
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :show, :id => item_has_use_restriction.id
        assigns(:item_has_use_restriction).should eq(item_has_use_restriction)
      end
    end

    describe "When not logged in" do
      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :show, :id => item_has_use_restriction.id
        assigns(:item_has_use_restriction).should eq(item_has_use_restriction)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        get :new
        assigns(:item_has_use_restriction).should_not be_valid
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "should not assign the requested item_has_use_restriction as @item_has_use_restriction" do
        get :new
        assigns(:item_has_use_restriction).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested item_has_use_restriction as @item_has_use_restriction" do
        get :new
        assigns(:item_has_use_restriction).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested item_has_use_restriction as @item_has_use_restriction" do
        get :new
        assigns(:item_has_use_restriction).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :edit, :id => item_has_use_restriction.id
        assigns(:item_has_use_restriction).should eq(item_has_use_restriction)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :edit, :id => item_has_use_restriction.id
        assigns(:item_has_use_restriction).should eq(item_has_use_restriction)
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :edit, :id => item_has_use_restriction.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested item_has_use_restriction as @item_has_use_restriction" do
        item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
        get :edit, :id => item_has_use_restriction.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:item_has_use_restriction)
      @invalid_attrs = {:item_id => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @attrs
          assigns(:item_has_use_restriction).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :item_has_use_restriction => @attrs
          response.should redirect_to(assigns(:item_has_use_restriction))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @invalid_attrs
          assigns(:item_has_use_restriction).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :item_has_use_restriction => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @attrs
          assigns(:item_has_use_restriction).should be_valid
        end

        it "should be forbidden" do
          post :create, :item_has_use_restriction => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @invalid_attrs
          assigns(:item_has_use_restriction).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :item_has_use_restriction => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @attrs
          assigns(:item_has_use_restriction).should be_valid
        end

        it "should be forbidden" do
          post :create, :item_has_use_restriction => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @invalid_attrs
          assigns(:item_has_use_restriction).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :item_has_use_restriction => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @attrs
          assigns(:item_has_use_restriction).should be_valid
        end

        it "should be forbidden" do
          post :create, :item_has_use_restriction => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved item_has_use_restriction as @item_has_use_restriction" do
          post :create, :item_has_use_restriction => @invalid_attrs
          assigns(:item_has_use_restriction).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :item_has_use_restriction => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
      @attrs = FactoryGirl.attributes_for(:item_has_use_restriction)
      @invalid_attrs = {:item_id => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
        end

        it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
          assigns(:item_has_use_restriction).should eq(@item_has_use_restriction)
          response.should redirect_to(@item_has_use_restriction)
        end
      end

      describe "with invalid params" do
        it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @invalid_attrs
          assigns(:item_has_use_restriction).should eq(@item_has_use_restriction)
        end

        it "should be forbidden" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
          assigns(:item_has_use_restriction).should eq(@item_has_use_restriction)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested item_has_use_restriction as @item_has_use_restriction" do
          put :update, :id => @item_has_use_restriction.id, :item_has_use_restriction => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @item_has_use_restriction = FactoryGirl.create(:item_has_use_restriction)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested item_has_use_restriction" do
        delete :destroy, :id => @item_has_use_restriction.id
      end

      it "redirects to the item_has_use_restrictions list" do
        delete :destroy, :id => @item_has_use_restriction.id
        response.should redirect_to(item_has_use_restrictions_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested item_has_use_restriction" do
        delete :destroy, :id => @item_has_use_restriction.id
      end

      it "redirects to the item_has_use_restrictions list" do
        delete :destroy, :id => @item_has_use_restriction.id
        response.should be_forbidden
      end
    end

    describe "When logged in as Subject" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested item_has_use_restriction" do
        delete :destroy, :id => @item_has_use_restriction.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @item_has_use_restriction.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested item_has_use_restriction" do
        delete :destroy, :id => @item_has_use_restriction.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @item_has_use_restriction.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
