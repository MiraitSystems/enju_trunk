# encoding: utf-8
require 'spec_helper'

describe ManifestationsController do
  fixtures :all

  describe '#create_from_ncidは', :solr => true do
    include NacsisCatSpecHelper

    def set_nacsis_search_each(v)
      update_system_configuration('nacsis.search_each', v)
    end

    before do
      Rails.cache.clear # SystemConfiguration由来の値が不定になるのを避けるため
      set_nacsis_search_each(true) # このブロックではnacsis.search_each==trueを基本とする
    end

    let(:nacsis_cat) do
      nacsis_cat_with_mock_record
    end

    let(:valid_params) do
      {
        ncid: nacsis_cat.ncid,
        manifestation_type: 'book',
      }
    end

    before do
      FactoryGirl.create(
        :manifestation_type,
        name: 'japanese_book')
      FactoryGirl.create(
        :manifestation_type,
        name: 'foreign_book')
      FactoryGirl.create(
        :manifestation_type,
        name: 'japanese_monograph')

      NacsisCat.stub(:search) do |opts|
        {book: [nacsis_cat]}
      end
    end

    describe '未登録のNCIDのとき' do
      it '指定されたNCIDによりManifestationレコードを作成すること' do
        expect {
          post :create_from_nacsis, valid_params
        }.to change(Manifestation, :count).by(1)
        expect(Manifestation.last.nacsis_identifier).to eq(nacsis_cat.ncid)
      end

      it '作成されたManifestaionレコードのページにリダイレクトすること' do
        post :create_from_nacsis, valid_params
        expect(response).to redirect_to manifestation_path(Manifestation.last)
      end
    end

    describe '登録済みのNCIDのとき' do
      before do
        Manifestation.create_from_ncid(nacsis_cat.ncid)
      end

      it '新しいレコードを作成しないこと' do
        expect {
          post :create_from_nacsis, valid_params
        }.not_to change(Manifestation, :count)
      end

      it '登録済みManifestaionレコードのページにリダイレクトすること' do
        manifestation = Manifestation.where(nacsis_identifier: nacsis_cat.ncid).first

        post :create_from_nacsis, valid_params
        expect(response).to redirect_to manifestation_path(manifestation)
      end
    end

    describe '不正なNCIDのとき' do
      it 'NACISレコード表示ページにリダイレクトすること' do
        Manifestation.any_instance.stub(:save) { false }

        post :create_from_nacsis, valid_params
        expect(response).to redirect_to nacsis_manifestations_path(
          ncid: nacsis_cat.ncid, manifestation_type: 'book')
      end
    end
  end
end
