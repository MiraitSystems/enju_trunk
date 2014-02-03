# encoding: utf-8
require 'spec_helper'

describe ResourceImportNacsisfilesController do

  describe '#createは' do
    let(:valid_params) do
      {
        resource_import_nacsis: fixture_file_upload("/../../examples/resource_import_nacsisfile_sample1.tsv", 'text/csv'),
      }
    end
    let(:user) do
      FactoryGirl.create(:librarian)
    end

    before do
      sign_in user

      @tmpdir = Dir.mktmpdir
      @save_base_dir = UserFile.base_dir
      UserFile.base_dir = @tmpdir
    end

    after do
      UserFile.base_dir = @save_base_dir
      FileUtils.remove_entry_secure(@tmpdir)
    end

    it 'ファイルを受け取ってローカルに保存すること' do
      post :create, valid_params
      user_file = UserFile.new(user)
      files = user_file.find(:resource_import_nacsisfile, '*')
      expect(files).to have(1).item
    end
  end

end
