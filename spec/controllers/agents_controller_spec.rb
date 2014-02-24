# encoding: utf-8
require 'spec_helper'

describe AgentsController do
  fixtures :all

  describe "GET index", :solr => true do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end
    end

    describe "When not logged in" do
      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end

      it "assigns all agents as @agents in rss format" do
        get :index, :format => :rss
        assigns(:agents).should_not be_empty
      end

      it "assigns all agents as @agents in atom format" do
        get :index, :format => :atom
        assigns(:agents).should_not be_empty
      end
    end

    describe '検索文字列として' do
      let(:fulltext_attr) do
        [
          :full_name,
          :full_name_transcription,
          :full_name_alternative,
          :place, :address_1, :address_2,
          :other_designation, :note,
        ]
      end

      let(:random_kanji) do
        %(
          亜唖娃阿哀愛挨姶逢葵茜穐悪握渥
          旭葦芦鯵梓圧斡扱宛姐虻飴絢綾鮎或
          粟袷安庵按暗案闇鞍杏以伊位依偉囲
          夷委威尉惟意慰易椅為畏異移維緯胃
          萎衣謂違遺医井亥域育郁磯一壱溢逸
          稲茨芋鰯允印咽員因姻引飲淫胤蔭
        ).gsub(/\s*/, '').scan(/./)
      end

      let(:random_kanji_used) do
        []
      end

      def shift_random_kanji
        k = random_kanji.shift
        raise 'kanji empty' unless k # テスト用の漢字が足りなかった
        random_kanji_used << k
        k
      end

      before do
        # XXX:
        # Agent.change_noteでUser.current_userを参照している。
        # User.current_userに中途半端なUserが設定されていると
        # テストの挙動(というよりもコントローラから以外での
        # Agentレコード作成)に副作用が出てしまうため
        # 念のために設定値を調整しておく。
        save_user_current_user = User.current_user
        User.current_user = nil

        Sunspot.remove_all!
        fulltext_attr.each do |a|
          k = shift_random_kanji
          kk = shift_random_kanji + shift_random_kanji
          kkk = shift_random_kanji + shift_random_kanji + shift_random_kanji

          FactoryGirl.create(:agent, a => k)
          FactoryGirl.create(:agent, a => kk)
          FactoryGirl.create(:agent, a => kkk)
        end
        Sunspot.commit

        User.current_user = save_user_current_user
      end

      before do
        sign_in FactoryGirl.create(:user)
      end

      it '1文字だけが与えられたとき検索できること' do
        while k = random_kanji_used.shift
          get :index, query: k
          expect(response).to be_success
          agents = assigns(:agents)
          expect(agents).to be_present
          expect(agents).to have(1).item
        end

        k = random_kanji.last # 未使用漢字
        get :index, query: k
        expect(response).to be_success
        agents = assigns(:agents)
        expect(agents).to be_blank
      end

      it '1文字検索語が複数与えられたとき検索できること' do
        last_word_chars = random_kanji_used[-3, 3]
        last_agent = Agent.where(fulltext_attr.last => last_word_chars.join).first

        last_agent.full_name = 'あいう えお'
        last_agent.save!
        Sunspot.commit

        get :index, query: "#{last_word_chars[0]} #{last_word_chars[2]}"
        expect(response).to be_success
        agents = assigns(:agents)
        expect(agents).to be_present
        expect(agents).to have(1).item
        expect(agents.first).to eq(last_agent)


        get :index, query: "\"いう え\" #{last_word_chars[2]}"
        expect(response).to be_success
        agents = assigns(:agents)
        expect(agents).to be_present
        expect(agents).to have(1).item
        expect(agents.first).to eq(last_agent)

        get :index, query: "#{random_kanji_used[0]} #{random_kanji_used[-1]}"
        expect(response).to be_success
        agents = assigns(:agents)
        expect(agents).to be_blank
      end
    end
  end

  describe "GET show" do
    before(:each) do
      @agent = FactoryGirl.create(:agent)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end
    end

    describe "When not logged in" do
      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "should not assign the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "assigns the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        assigns(:agent).should eq(agent)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "assigns the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        assigns(:agent).should eq(agent)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "assigns the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = FactoryGirl.attributes_for(:agent)
      @invalid_attrs = FactoryGirl.attributes_for(:agent, :full_name => '')
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :agent => @attrs
          response.should redirect_to(agent_url(assigns(:agent)))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :agent => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :agent => @attrs
          response.should redirect_to(agent_url(assigns(:agent)))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :agent => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @agent = FactoryGirl.create(:agent)
      @attrs = FactoryGirl.attributes_for(:agent)
      @invalid_attrs = FactoryGirl.attributes_for(:agent, :full_name => '')
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @attrs
          assigns(:agent).should eq(@agent)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @attrs
          assigns(:agent).should eq(@agent)
          response.should redirect_to(@agent)
        end
      end

      describe "with invalid params" do
        it "assigns the agent as @agent" do
          put :update, :id => @agent, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @agent, :agent => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @attrs
          assigns(:agent).should eq(@agent)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @agent.id, :agent => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @agent = FactoryGirl.create(:agent)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end

      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "redirects to the agents list" do
        delete :destroy, :id => @agent.id
        response.should redirect_to(agents_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in FactoryGirl.create(:librarian)
      end

      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "redirects to the agents list" do
        delete :destroy, :id => @agent.id
        response.should redirect_to(agents_url)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in FactoryGirl.create(:user)
      end

      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
