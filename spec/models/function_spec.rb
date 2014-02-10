# encoding: utf-8
require 'spec_helper'

describe Function do
  describe '.newは' do
    def new_and_validate(opts = {})
      obj = Function.new(opts)
      obj.valid?
      obj
    end

    it '存在するコントローラ名を受け入れること' do
      obj = new_and_validate(controller_name: 'ManifestationsController')
      expect(obj.errors[:controller_name]).to be_blank

      obj = new_and_validate(controller_name: 'NotExistsController')
      expect(obj.errors[:controller_name]).to be_present
    end

    it '不正なコントローラ名を受け入れないこと' do
      obj = new_and_validate(controller_name: 'InvalidNames')
      expect(obj.errors[:controller_name]).to be_present
    end

    it '空の表示名を受け入れないこと' do
      obj = new_and_validate(display_name: 'Test')
      expect(obj.errors[:display_name]).to be_blank

      obj = new_and_validate(display_name: '')
      expect(obj.errors[:display_name]).to be_present

      obj = new_and_validate(display_name: nil)
      expect(obj.errors[:display_name]).to be_present
    end

    it '空のポジションを受け入れないこと' do
      obj = new_and_validate(position: 1)
      expect(obj.errors[:position]).to be_blank

      obj = new_and_validate(position: nil)
      expect(obj.errors[:position]).to be_present
    end

    it '正しい書式のアクションリストを受け入れること' do
      # 正しい書式
      [
        "read:\nupdate:\ndelete:\n",
        "update:\ndelete:\nread:\n",
        "delete:\nread:\nupdate:\n",
        "read:foo\nupdate:bar\ndelete:baz\n",
        "read:foo,bar\nupdate:\ndelete:baz\n",
        "read:foo,bar,baz\nupdate:\ndelete:baz\n",
      ].each do |action_names|
        obj = new_and_validate(action_names: action_names)
        expect(obj.errors[:action_names]).to be_blank,
          "expected valid for \"#{action_names}\", got invalid"
      end
      # 不正な書式
      [
        "read:\nupdate:\ndelete:\n\n",
        "read:\nupdate:\n\ndelete:\n",
        "read:\nupdate:\ndelete:",
        "read:\nupdate:\n",
        "read:\n",
        "read:",
        "read:foo\nupdate:bar\ndelete:baz",
        "read:,foo\nupdate:\ndelete:\n",
        "read:foo,\nupdate:\ndelete:\n",
        "read:foo,,bar\nupdate:\ndelete:\n",
        "read:,\nupdate:\ndelete:\n",
      ].each do |action_names|
        obj = new_and_validate(action_names: action_names)
        expect(obj.errors[:action_names]).to be_present,
          "expected invalid for \"#{action_names}\", got valid"
      end
    end

    it '空のアクションリストを受け入れないこと' do
      obj = new_and_validate(action_names: nil)
      expect(obj.errors[:action_names]).to be_present

      obj = new_and_validate(action_names: '')
      expect(obj.errors[:action_names]).to be_present

      obj = new_and_validate(action_names: " ")
      expect(obj.errors[:action_names]).to be_present

      obj = new_and_validate(action_names: "  ")
      expect(obj.errors[:action_names]).to be_present

      obj = new_and_validate(action_names: "\n")
      expect(obj.errors[:action_names]).to be_present

      obj = new_and_validate(action_names: " \n ")
      expect(obj.errors[:action_names]).to be_present
    end
  end

  describe '#action_specは' do
    it 'action_namesを解析した結果をハッシュで返すこと' do
      obj = Function.new(action_names: <<-E)
read:index,show
update:new,create,edit,update
delete:destroy
      E
      expect(obj.action_spec).to eq({
        read: %w(index show),
        update: %w(new create edit update),
        delete: %w(destroy),
      })
    end
  end
end
