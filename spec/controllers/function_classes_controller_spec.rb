# encoding: utf-8
require 'spec_helper'

describe FunctionClassesController do

  let(:valid_attributes) do
    {
      display_name: 'Class1',
      name: 'class1',
      position: 1,
    }
  end

  let(:valid_params) do
    {
      'display_name' => 'Class1',
      'name' => 'class1',
      'position' => '1',
    }
  end

  let(:valid_session) do
    {}
  end

  before do
    FactoryGirl.create(:function_class, valid_attributes)
  end

  describe '#indexは' do
    it 'すべてのレコードを@function_classesに設定すること' do
      get :index, {}, valid_session
      expect(response).to be_success
      expect(assigns(:function_classes)).to be_present
      expect(assigns(:function_classes)).to eq(FunctionClass.all)
    end
  end

  describe '#showは' do
    it '指定されたレコードを@function_classに設定すること' do
      function_class = FunctionClass.last
      get :show, {:id => function_class.to_param}, valid_session
      expect(response).to be_success
      expect(assigns(:function_class)).to be_present
      expect(assigns(:function_class)).to eq(function_class)
    end
  end

  describe '#newは' do
    it '新しいレコードを@function_classに設定すること' do
      get :new, {}, valid_session
      expect(response).to be_success
      expect(assigns(:function_class)).to be_present
      expect(assigns(:function_class)).to be_a_new(FunctionClass)
    end
  end

  describe '#editは' do
    it '指定されたレコードを@function_classに設定すること' do
      function_class = FunctionClass.last
      get :edit, {:id => function_class.to_param}, valid_session
      expect(response).to be_success
      expect(assigns(:function_class)).to be_present
      expect(assigns(:function_class)).to eq(function_class)
    end
  end

  describe '#createは' do
    describe '正しいパラメータが与えられたとき' do
      it '新しいレコードを作成すること' do
        expect {
          post :create, {:function_class => valid_params}, valid_session
        }.to change(FunctionClass, :count).by(1)
      end

      it '新しいレコードを@function_classに設定すること' do
        post :create, {:function_class => valid_params}, valid_session
        expect(assigns(:function_class)).to be_a(FunctionClass)
        expect(assigns(:function_class)).to be_persisted
      end

      it '新しいレコードの照参画面にリダイレクトすること' do
        post :create, {:function_class => valid_params}, valid_session
        expect(response).to redirect_to(FunctionClass.last)
      end
    end

    describe '不正なパラメータが与えられたとき' do
      let(:invalid_params) do
        valid_params.merge({'position' => '-1'})
      end

      it 'レコードを作成しないこと' do
        expect {
          post :create, {:function_class => invalid_params}, valid_session
        }.not_to change(FunctionClass, :count)
      end

      it 'セーブされていない新しいレコードを@function_classに設定すること' do
        post :create, {:function_class => invalid_params}, valid_session
        expect(assigns(:function_class)).to be_a_new(FunctionClass)
      end

      it 'newテンプレートをレンダリングすること' do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, {:function_class => invalid_params}, valid_session
        expect(response).to be_success
        expect(response).to render_template('new')
      end
    end
  end

  describe '#updateは' do
    describe '正しいパラメータが与えられたとき' do
      it '指定されたレコードを更新すること' do
        function_class = FunctionClass.last
        # Assuming there are no other function_classes in the database, this
        # specifies that the FunctionClass created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        FunctionClass.any_instance.should_receive(:update_attributes).with({'display_name' => 'MyText' })
        put :update, {:id => function_class.to_param, :function_class => {'display_name' => 'MyText'}}, valid_session
      end

      it '指定されたレコードを@function_classに設定すること' do
        function_class = FunctionClass.last
        put :update, {:id => function_class.to_param, :function_class => valid_params}, valid_session
        expect(assigns(:function_class)).to be_present
        expect(assigns(:function_class)).to eq(function_class)
      end

      it '指定されたレコードの参照画面にリダイレクトすること' do
        function_class = FunctionClass.last
        put :update, {:id => function_class.to_param, :function_class => valid_params}, valid_session
        expect(response).to redirect_to(function_class)
      end
    end

    describe '不正なパラメータが与えられたとき' do
      let(:invalid_params) do
        {'position' => '-1'}
      end

      it '指定されたレコードを@function_classに設定すること' do
        function_class = FunctionClass.last
        put :update, {:id => function_class.to_param, :function_class => invalid_params}, valid_session
        expect(assigns(:function_class)).to be_present
        expect(assigns(:function_class)).to eq(function_class)
      end

      it 'editテンプレートをレンダリングすること' do
        function_class = FunctionClass.last
        put :update, {:id => function_class.to_param, :function_class => invalid_params}, valid_session
        expect(response).to be_success
        expect(response).to render_template("edit")
      end
    end
  end

  describe '#destroyは' do
    it '指定されたレコードを削除すること' do
      function_class = FunctionClass.last
      expect {
        delete :destroy, {:id => function_class.to_param}, valid_session
      }.to change(FunctionClass, :count).by(-1)
    end

    it '一覧画面にリダイレクトすること' do
      function_class = FunctionClass.last
      delete :destroy, {:id => function_class.to_param}, valid_session
      expect(response).to redirect_to(function_classes_url)
    end
  end

end
