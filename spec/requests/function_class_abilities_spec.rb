# encoding: utf-8
require 'spec_helper'

describe "FunctionClassAbilities" do
  fixtures :all

  let(:user) do
    FactoryGirl.create(
      :admin,
      agent: FactoryGirl.create(:agent),
      function_class: nil)
  end

  def sign_in(user)
    post_via_redirect user_session_path,
      'user[username]' => user.username,
      'user[password]' => user.password
  end

  def define_function(controller_class, actions)
    if actions.is_a?(Hash)
      actions = ({read: [], update: [], delete: []}.merge(actions)).
        inject('') do |text, (type, methods)|
          text << "#{type}:#{methods.join(',')}\n"
        end
    end

    FactoryGirl.create(
      :function,
      controller_name: controller_class.name,
      display_name: controller_class.name,
      action_names: actions)
  end

  def define_function_class(name)
    FactoryGirl.create(
      :function_class,
      display_name: name,
      name: name)
  end

  def define_function_class_and_ability(fclass, spec)
    unless fclass.is_a?(FunctionClass)
      fclass = define_function_class(fclass.to_s)
    end

    spec.each do |function, ability|
      FactoryGirl.create(
        :function_class_ability,
        function_class: fclass,
        function: function,
        ability: ability)
    end
  end

  def expect_response_to_be_success
    expect(response.status).to eq(200)
  end

  def expect_response_not_to_be_success
    expect(response.status).not_to eq(200) # NOTE: ログイン状態なら403、未ログイン状態なら302
  end

  before(:all) do
    LibrariesController.class_eval do
      authorize_function
    end
  end

  before do
    Function.destroy_all
  end

  after do
    Function.destroy_all
  end

  describe '未ログイン状態のとき' do
    it '機能制限設定がなければアクセスできること' do
      get libraries_path
      expect_response_to_be_success
    end

    it '機能制限設定があればアクセスできないこと' do
      define_function(LibrariesController, read: %w(index))

      get libraries_path
      expect_response_not_to_be_success
    end

    it '機能制限設定があり、nobodyクラスで許可されていなければアクセスできること' do
      function = define_function(LibrariesController, read: %w(index))
      fcability = define_function_class_and_ability(
        'nobody', {function => 0})

      get libraries_path
      expect_response_not_to_be_success
    end

    it '機能制限設定があり、nobodyクラスで許可されていればアクセスできること' do
      function = define_function(LibrariesController, read: %w(index))
      fcability = define_function_class_and_ability(
        'nobody', {function => 1})

      get libraries_path
      expect_response_to_be_success
    end
  end

  describe '機能クラス未所属ユーザでログイン状態のとき' do
    before do
      sign_in(user)
    end

    it '機能制限設定がなければアクセスできること' do
      get libraries_path
      expect_response_to_be_success
    end

    it '機能制限設定があればアクセスできないこと' do
      define_function(LibrariesController, read: %w(index))

      get libraries_path
      expect_response_not_to_be_success
    end

    it '機能制限設定があり、noclassクラスで許可されていなければアクセスできること' do
      function = define_function(LibrariesController, read: %w(index))
      fcability = define_function_class_and_ability(
        'noclass', {function => 0})

      get libraries_path
      expect_response_not_to_be_success
    end

    it '機能制限設定があり、noclassクラスで許可されていればアクセスできること' do
      function = define_function(LibrariesController, read: %w(index))
      fcability = define_function_class_and_ability(
        'noclass', {function => 1})

      get libraries_path
      expect_response_to_be_success
    end
  end

  describe '機能クラス所属ユーザでログイン状態のとき' do
    before do
      user.function_class = define_function_class('class1')
      user.save!

      sign_in(user)
    end

    it '機能制限設定がなければアクセスできること' do
      get libraries_path
      expect_response_to_be_success
    end

    it '機能制限設定があればアクセスできないこと' do
      define_function(LibrariesController, read: %w(index))

      get libraries_path
      expect_response_not_to_be_success
    end

    it '機能制限設定があり、所属クラスで許可されていなければアクセスできること' do
      function = define_function(LibrariesController, read: %w(index))
      fcability = define_function_class_and_ability(
        user.function_class, {function => 0})

      get libraries_path
      expect_response_not_to_be_success
    end

    it '機能制限設定があり、所属クラスで許可されていればアクセスできること' do
      function = define_function(LibrariesController, read: %w(index))
      fcability = define_function_class_and_ability(
        user.function_class, {function => 1})

      get libraries_path
      expect_response_to_be_success
    end
  end

end
