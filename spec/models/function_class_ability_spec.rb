# encoding: utf-8
require 'spec_helper'

describe FunctionClassAbility do
  fixtures :user_groups, :agent_types, :libraries, :countries, :languages, :roles

  describe '.newは' do
    subject { FunctionClassAbility }

    def new_and_validate(opts = {})
      obj = subject.new(opts)
      obj.valid?
      obj
    end

    before do
      FactoryGirl.create(:function)
      FactoryGirl.create(:function_class)
    end

    it '存在する機能を受け入れること' do
      function = Function.last
      obj = new_and_validate(function: function)
      expect(obj.errors[:function]).to be_blank

      obj = new_and_validate(function: Function.new)
      expect(obj.errors[:function]).to be_present
    end

    it '空の機能を受け入れないこと' do
      obj = new_and_validate(function: nil)
      expect(obj.errors[:function]).to be_present
    end

    it '存在する利用者グループを受け入れること' do
      function_class = FunctionClass.last
      obj = new_and_validate(function_class: function_class)
      expect(obj.errors[:function_class]).to be_blank

      obj = new_and_validate(function_class: FunctionClass.new)
      expect(obj.errors[:function_class]).to be_present
    end

    it '空の利用者グループを受け入れないこと' do
      obj = new_and_validate(function_class: nil)
      expect(obj.errors[:function_class]).to be_present
    end

    it '0以上の権限を受け入れること' do
      [0, 1, 2, 3].each do |n|
        obj = new_and_validate(ability: n)
        expect(obj.errors[:ability]).to be_blank
      end

      obj = new_and_validate(ability: -1)
      expect(obj.errors[:ability]).to be_present
    end

    it '空の権限を受け入れないこと' do
      obj = new_and_validate(ability: nil)
      expect(obj.errors[:ability]).to be_present
    end
  end

  describe '.permit?は' do
    let(:common_action_names) do
      <<-E
read:index,show
update:new,create,edit,update
delete:destroy
      E
    end

    let(:function1) do
      FactoryGirl.create(
        :function,
        display_name: 'Manifestations',
        controller_name: 'ManifestationsController',
        action_names: common_action_names)
    end

    let(:function2) do
      FactoryGirl.create(
        :function,
        display_name: 'Items',
        controller_name: 'ItemsController',
        action_names: common_action_names)
    end

    let(:function3) do
      FactoryGirl.create(
        :function,
        display_name: 'Libraries',
        controller_name: 'LibrariesController',
        action_names: common_action_names)
    end

    let(:function4) do
      FactoryGirl.create(
        :function,
        display_name: 'LibrariesX',
        controller_name: 'LibrariesController',
        action_names: <<-E)
read:show,edit,destroy
update:new,create
delete:index
        E
    end

    let(:class1) do
      FactoryGirl.create(:function_class, name: 'class1', display_name: 'class1')
    end

    let(:class2) do
      FactoryGirl.create(:function_class, name: 'class2', display_name: 'class2')
    end

    let(:class3) do
      FactoryGirl.create(:function_class, name: 'class3', display_name: 'class3')
    end

    let(:guest) do
      FactoryGirl.create(
        :user,
        username: '_guest_',
        agent: FactoryGirl.create(:agent),
        function_class: nil)
    end

    let(:user) do
      FactoryGirl.create(
        :user,
        username: '_user_',
        agent: FactoryGirl.create(:agent),
        function_class: class1)
    end

    let(:admin) do
      FactoryGirl.create(
        :user,
        username: '_admin_',
        agent: FactoryGirl.create(:agent),
        function_class: class2)
    end

    let(:user3) do
      FactoryGirl.create(
        :user,
        username: '_user3_',
        agent: FactoryGirl.create(:agent),
        function_class: class3)
    end

    def permit_for_user?(controller_class, action_name, user)
      FunctionClassAbility.permit?(controller_class, action_name, user)
    end

    def define_function_class_ability(spec)
      spec.each do |function_class, definition|
        definition.each do |function, ability|
          FactoryGirl.create(
            :function_class_ability,
            function: function,
            function_class: function_class,
            ability: ability)
        end
      end
    end

    before do
      define_function_class_ability({
        class1 => {
          function1 => 1,
          function2 => 0,
        },
        class2 => {
          function1 => 1,
          function2 => 2,
          function3 => 3,
        },
        class3 => {
          function3 => 1,
          function4 => 3,
        },
      })
    end

    it 'ユーザが機能に対する権限を持っていたらtrueを返すこと' do
      {
        user => { # userはclass1に属す
          ManifestationsController => {
            %w(index show) => true,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
        },
        admin => { # userはclass2に属す
          ManifestationsController => {
            %w(index show) => true,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => true,
            %w(new create edit update) => true,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => true,
            %w(new create edit update) => true,
            %w(destroy) => true,
          },
        },
        user3 => { # user3はclass3に属す
          ManifestationsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => true, # function3、function4による許可
            %w(edit destroy) => true, # function4による許可
            %w(new create) => true, # function4による許可
            %w(update) => false,
          },
        },
        guest => { # guestはどれにも属さない
          ManifestationsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
        },
        nil => { # ユーザが未定義の場合はFunctionClassに属さないケースと同じ
          ManifestationsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => false,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
        },
      }.each do |u, specs|
        specs.each do |controller_class, spec|
          spec.each do |action_names, permission|
            action_names.each do |action_name|
              expect(permit_for_user?(controller_class, action_name, u)).to eq(permission),
                "expects #{permission} for #{u.try(:username) || '""'} to access #{controller_class.name}\##{action_name}, got #{!permission}"
            end
          end
        end
      end
    end

    describe '機能クラスnoclassが設定されているとき' do
      let(:noclass) do
        FactoryGirl.create(:function_class, name: 'noclass', display_name: 'No Class')
      end

      before do
        define_function_class_ability({
          noclass => {
            function1 => 1,
            function2 => 2,
            function3 => 3,
          }
        })
      end

      it '機能クラス未所属ユーザに対してnoclassへの許可設定により判定すること' do
        user = guest # guestはどのFunctionClassにも属さない
        {
          ManifestationsController => {
            %w(index show) => true,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => true,
            %w(new create edit update) => true,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => true,
            %w(new create edit update) => true,
            %w(destroy) => true,
          },
        }.each do |controller_class, spec|
          spec.each do |action_names, permission|
            action_names.each do |action_name|
              expect(permit_for_user?(controller_class, action_name, user)).to eq(permission),
                "expects #{permission} for #{user.try(:username) || '""'} to access #{controller_class.name}\##{action_name}, got #{!permission}"
            end
          end
        end
      end
    end

    describe '機能クラスnobodyが設定されているとき' do
      let(:nobody) do
        FactoryGirl.create(:function_class, name: 'nobody', display_name: 'Nobody')
      end

      before do
        define_function_class_ability({
          nobody => {
            function1 => 1,
            function2 => 2,
            function3 => 3,
          }
        })
      end

      it '非ログイン利用に対してnobodyへの許可設定により判定すること' do
        user = nil
        {
          ManifestationsController => {
            %w(index show) => true,
            %w(new create edit update) => false,
            %w(destroy) => false,
          },
          ItemsController => {
            %w(index show) => true,
            %w(new create edit update) => true,
            %w(destroy) => false,
          },
          LibrariesController => {
            %w(index show) => true,
            %w(new create edit update) => true,
            %w(destroy) => true,
          },
        }.each do |controller_class, spec|
          spec.each do |action_names, permission|
            action_names.each do |action_name|
              expect(permit_for_user?(controller_class, action_name, user)).to eq(permission),
                "expects #{permission} for #{user.try(:username) || '""'} to access #{controller_class.name}\##{action_name}, got #{!permission}"
            end
          end
        end
      end
    end

    it '制限設定のないコントローラが指定されたときtrueを返すこと' do
      controller_class = ShelvesController # 機能制限対象として設定されていない
      %w(index show new create edit update destroy).each do |action_name|
        expect(permit_for_user?(controller_class, action_name, guest)).to be_true
      end
    end

    it '制限設定のないアクションが指定されたときfalseを返すこと' do
      # LibrariesControllerは機能制限対象として設定されているが
      # function_class_ability_testアクションに対する設定はない
      controller_class = LibrariesController
      action_name = 'function_class_ability_test'
      expect(permit_for_user?(controller_class, action_name, admin)).to be_false
    end

  end
end
