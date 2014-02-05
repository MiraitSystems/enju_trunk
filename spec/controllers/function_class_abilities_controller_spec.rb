# encoding: utf-8
require 'spec_helper'

describe FunctionClassAbilitiesController do

  let(:valid_session) { {} }

  let(:function1) do
    FactoryGirl.create(
      :function,
      controller_name: 'ManifestationsController',
      display_name: 'Manifestations',
      position: 1)
  end

  let(:function2) do
    FactoryGirl.create(
      :function,
      controller_name: 'ItemsController',
      display_name: 'Items',
      position: 2)
  end

  let(:function_class1) do
    FactoryGirl.create(:function_class)
  end

  let(:function_class2) do
    FactoryGirl.create(:function_class)
  end

  before do
    # function_class1: テストのためfunction1に対してのみ設定し、funcion2に対しては設定しない
    FactoryGirl.create(
      :function_class_ability,
      function_class: function_class1,
      function: function1,
      ability: 1)

    # function_class2: function1、function2の両方に設定する
    FactoryGirl.create(
      :function_class_ability,
      function_class: function_class2,
      function: function1,
      ability: 1)
    FactoryGirl.create(
      :function_class_ability,
      function_class: function_class2,
      function: function2,
      ability: 1)
  end


  describe '#indexは' do
    it '機能区分に設定可能な権限を@function_class_abilitiesに設定すること' do
      get :index, {'function_class_id' => function_class1.id.to_s}, valid_session
      expect(response).to be_success
      expect(assigns(:function_class_abilities)).to be_present
      expect(assigns(:function_class_abilities)).to have(Function.count).items
    end

    it '未設定の権限があれば新たにレコードを生成すること' do
      get :index, {'function_class_id' => function_class1.id.to_s}, valid_session
      fc_abilities = assigns(:function_class_abilities)

      fc_ability_saved = fc_abilities.detect {|ability| ability.function_id == function1.id }
      fc_ability_new   = fc_abilities.detect {|ability| ability.function_id != function1.id }

      expect(fc_ability_saved).to be_persisted
      expect(fc_ability_saved).to eq(
        FunctionClassAbility.where(
          function_class_id: function_class1.id,
          function_id: function1.id).first)

      expect(fc_ability_new).to be_a_new(FunctionClassAbility)
      expect(fc_ability_new.ability).to eq(0)
    end
  end

  describe '#update_allは' do
    let(:valid_params) do
      {
        'function_class_id' => function_class1.id.to_s,
        'function_class_abilities' => {
          function1.id.to_s => 3,
          function2.id.to_s => 3,
        },
      }
    end

    describe '正しいパラメータが与えられたとき' do
      it '権限を設定すること' do
        expect {
          post :update_all, valid_params, valid_session
        }.to change(FunctionClassAbility, :count).by(1) # 未設定だった機能のためにレコードが作成される

        FunctionClassAbility.
          where(function_class_id: function_class1.id).
          all.each do |fc_ability|
            expect(fc_ability.ability).to eq(3)
          end
      end

      it '一覧ページにリダイレクトすること' do
        post :update_all, valid_params, valid_session
        expect(response).to redirect_to(
          function_class_function_class_abilities_path(function_class_id: function_class1))
      end
    end

    describe '権限パラメータが空のとき' do
      let(:empty_params) do
        valid_params.dup.tap do |h|
          h.delete('function_class_abilities')
        end
      end

      it '一覧ページにリダイレクトすること' do
        post :update_all, empty_params, valid_session
        expect(response).to redirect_to(
          function_class_function_class_abilities_path(function_class_id: function_class1))
      end
    end
  end

end
