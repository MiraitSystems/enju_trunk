require 'spec_helper'

describe BookmarksController do
  fixtures :all

  describe "GET index", :solr => true do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all bookmarks as @bookmarks" do
        get :index
        assigns(:bookmarks).should_not be_empty
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all bookmarks as @bookmarks" do
        get :index
        assigns(:bookmarks).should_not be_empty
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all bookmarks as @bookmarks" do
        get :index
        assigns(:bookmarks).should_not be_empty
      end
    end

    describe "When not logged in" do
      it "assigns all bookmarks as @bookmarks" do
        get :index
        assigns(:bookmarks).should be_empty
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested bookmark as @bookmark" do
        bookmark = FactoryGirl.create(:bookmark)
        get :show, :id => bookmark.id
        assigns(:bookmark).should eq(bookmark)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested bookmark as @bookmark" do
        bookmark = FactoryGirl.create(:bookmark)
        get :show, :id => bookmark.id
        assigns(:bookmark).should eq(bookmark)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested bookmark as @bookmark" do
        bookmark = FactoryGirl.create(:bookmark)
        get :show, :id => bookmark.id
        assigns(:bookmark).should eq(bookmark)
      end
    end

    describe "When not logged in" do
      it "assigns the requested bookmark as @bookmark" do
        bookmark = FactoryGirl.create(:bookmark)
        get :show, :id => bookmark.id
        assigns(:bookmark).should eq(bookmark)
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @bookmark = bookmarks(:bookmark_00001)
      @attrs = FactoryGirl.attributes_for(:bookmark)
      @invalid_attrs = {:url => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        @user = FactoryGirl.create(:admin)
        sign_in @user
      end

      describe "with valid params" do
        it "updates the requested bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
        end

        it "assigns the requested bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
          assigns(:bookmark).should eq(@bookmark)
          response.should redirect_to user_bookmark_url(@bookmark.user, @bookmark)
        end
      end

      describe "with invalid params" do
        it "assigns the requested bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @invalid_attrs
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @bookmark.id, :bookmark => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        @user = FactoryGirl.create(:librarian)
        sign_in @user
      end

      describe "with valid params" do
        it "updates the requested bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
        end

        it "assigns the requested bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
          assigns(:bookmark).should eq(@bookmark)
          response.should redirect_to user_bookmark_url(@bookmark.user, @bookmark)
        end
      end

      describe "with invalid params" do
        it "assigns the bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @invalid_attrs
          assigns(:bookmark).should_not be_valid
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @bookmark.id, :bookmark => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        @user = FactoryGirl.create(:user)
        sign_in @user
      end

      describe "with valid params" do
        it "updates the requested bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
        end

        it "assigns the requested bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
          assigns(:bookmark).should eq(@bookmark)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @bookmark.id, :bookmark => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested bookmark as @bookmark" do
          put :update, :id => @bookmark.id, :bookmark => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @bookmark = bookmarks(:bookmark_00001)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested bookmark" do
        delete :destroy, :id => @bookmark.id
      end

      it "redirects to the bookmarks list" do
        delete :destroy, :id => @bookmark.id
        response.should redirect_to user_bookmarks_url(@bookmark.user)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested bookmark" do
        delete :destroy, :id => @bookmark.id
      end

      it "redirects to the bookmarks list" do
        delete :destroy, :id => @bookmark.id
        response.should redirect_to user_bookmarks_url(@bookmark.user)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested bookmark" do
        delete :destroy, :id => @bookmark.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @bookmark.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested bookmark" do
        delete :destroy, :id => @bookmark.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @bookmark.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
