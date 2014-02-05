# encoding: utf-8
require 'spec_helper'

describe FunctionClass do
  describe '.newは' do
    def new_and_validate(opts = {})
      obj = FunctionClass.new(opts)
      obj.valid?
      obj
    end

    it '空の名前を受け入れないこと' do
      obj = new_and_validate(name: 'Test')
      expect(obj.errors[:name]).to be_blank

      obj = new_and_validate(name: '')
      expect(obj.errors[:name]).to be_present

      obj = new_and_validate(name: nil)
      expect(obj.errors[:name]).to be_present
    end

    it '空の表示名を受け入れないこと' do
      obj = new_and_validate(display_name: 'Test')
      expect(obj.errors[:display_name]).to be_blank

      obj = new_and_validate(display_name: '')
      expect(obj.errors[:display_name]).to be_present

      obj = new_and_validate(display_name: nil)
      expect(obj.errors[:display_name]).to be_present
    end

    it '1以上のポジションを受け入れること' do
      obj = new_and_validate(position: 1)
      expect(obj.errors[:position]).to be_blank

      obj = new_and_validate(position: -1)
      expect(obj.errors[:position]).to be_present
    end

    it '空のポジションを受け入れないこと' do
      obj = new_and_validate(position: nil)
      expect(obj.errors[:position]).to be_present
    end
  end

  describe '.noclass_idは' do
    it 'nameが"noclass"であるレコードのidを返すこと' do
      fclass = FactoryGirl.create(:function_class, name: 'noclass')
      expect(FunctionClass.noclass_id).to eq(fclass.id)

      fclass.destroy
      expect(FunctionClass.noclass_id).to be_nil
    end
  end

  describe '.nobody_idは' do
    it 'nameが"nobody"であるレコードのidを返すこと' do
      fclass = FactoryGirl.create(:function_class, name: 'nobody')
      expect(FunctionClass.nobody_id).to eq(fclass.id)

      fclass.destroy
      expect(FunctionClass.nobody_id).to be_nil
    end
  end
end
