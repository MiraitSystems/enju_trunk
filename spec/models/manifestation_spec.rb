# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Manifestation, :solr => true do
  fixtures :all
  use_vcr_cassette "enju_ndl/manifestation", :record => :new_episodes

  let(:cs_in_process) do
    CirculationStatus.find_by_name('In Process') or raise '"In Process" not found'
  end
  let(:cs_in_factory) do
    CirculationStatus.find_by_name('In Factory') or raise '"In Factory" not found'
  end
  let(:cs_removed) do
    CirculationStatus.find_by_name('Removed') or raise '"Removed" not found'
  end
  let(:cs_available) do
    CirculationStatus.find_by_name('Available On Shelf') or raise '"Available On Shelf" not found'
  end

  # !!! notice !!!
  #
  # TODO: immediately の実装を優先してください
  # また、TODOになっている部分のテストメソッドを実装するときに既存テストで重複しているものがないか確認してください。
  #

  describe 'validates' do
    #validates_presence_of :carrier_type, :language, :manifestation_type, :country_of_publication
    it '' # TODO 
    #validates_associated :carrier_type, :language, :manifestation_type, :country_of_publication
    it '' # TODO
    #validates_numericality_of :acceptance_number, :allow_nil => true
    it '' # TODO
    #validate :check_rank
    it '' # TODO: immediately

    it 'nacsis_identifierが重複していたらエラーとすること' do
      ncid = 'foobar'
      FactoryGirl.create(:manifestation, nacsis_identifier: ncid)

      m = Manifestation.new(nacsis_identifier: ncid)
      m.valid?
      expect(m.errors).to include(:nacsis_identifier)
    end
  end

  describe 'before_validation' do
    #before_validation :set_language, :if => :during_import
    it '' # TODO
    #before_validation :uniq_options
    it '' # TODO
    #before_validation :set_manifestation_type, :set_country_of_publication
    it '' # TODO
  end

  describe 'before_save' do
    #before_save :set_series_statement
    it '' # TODO: immediately
  end

  describe 'after_save' do
    #after_save :index_series_statement
    it '' # TODO
  end

  describe 'after_destroy' do
    #after_destroy :index_series_statement
    it '' # TODO
  end

  describe 'search' do
    it '' # TODO: immediately
  end

  describe '#check_rank' do
    it '' # TODO: immediately
  end

  describe '#set_language' do
    it '' # TODO
  end

  describe '#set_manifestation_type' do
    it '' # TODO
  end

  describe '#root_of_series?' do
    it '' # TODO: immediately
  end

  describe '#serial?' do
    it '' # TODO: immediately
  end

  describe '#article?' do
    it '' # TODO: immediately
  end

  describe '#japanese_article?' do
    it '' # TODO
  end

  describe '#series?' do
    it '' # TODO
  end

  describe '#non_searchable?' do
    let(:rp_searchable) do
      FactoryGirl.create(
        :retention_period,
        non_searchable: false,
        name: 'non_searchable_test rp_searchable')
    end

    let(:rp_non_searchable) do
      FactoryGirl.create(
        :retention_period,
        non_searchable: true,
        name: 'non_searchable_test rp_non_searchable')
    end

    let(:cs_searchable) do
      FactoryGirl.create(
        :circulation_status,
        unsearchable: false,
        name: 'non_searchable_test cs_searchable')
    end

    let(:cs_unsearchable) do
      FactoryGirl.create(
        :circulation_status,
        unsearchable: true,
        name: 'non_searchable_test cs_unsearchable')
    end

    let(:manifestation) do
      m = FactoryGirl.create(:manifestation)

      # 所属に関するあらゆる条件でnon_searchable?==trueになるようにする(書誌自身の条件は除く)
      2.times do
        item = m.items.build(
          non_searchable: true,
          retention_period: rp_non_searchable,
          circulation_status: cs_unsearchable,
          rank: 2,
          item_identifier: "non_searchable_test_#{Item.count + 1}",
          manifestation: m
        )
        item.save!
      end
      expect(m).to be_non_searchable

      m
    end

    it 'periodical_masterがtrueであるなら常にfalseを返すこと' do
      manifestation.periodical_master = true
      expect(manifestation).not_to be_non_searchable
    end

    it '所蔵を持たないときtrueを返すこと' do
      manifestation.items.destroy_all
      expect(manifestation).to be_non_searchable
    end

    it '所蔵のいずれかが所定の条件を満たすならfalseを返すこと' do
      manifestation.stub(:article?) { true } # manifestationはarticleである
      update_system_configuration('manifestation.manage_item_rank', false) # manage_item_rankしない

      item = manifestation.items.first

      # itemはsearchableだがitem.retention_periodはnon_searchable -- 所定の条件を満たさない
      item.non_searchable = false
      item.retention_period = rp_non_searchable
      expect(manifestation).to be_non_searchable

      # item.retention_periodはsearchableだがitemはnon_searchable -- 所定の条件を満たさない
      item.non_searchable = true
      item.retention_period = rp_searchable
      expect(manifestation).to be_non_searchable

      # itemはsearchableで、item.retention_periodもsearchable -- (1) 条件を満たす
      item.non_searchable = false
      item.retention_period = rp_searchable
      expect(manifestation).not_to be_non_searchable

      manifestation.stub(:article?) { false } # manifestationはarticleでない
      # (1)+item.circulation_statusがunsearchable -- 所定の条件を満たさない
      expect(manifestation).to be_non_searchable

      # (1)+item.circulation_statusがsearchable -- (2) 条件を満たす
      item.circulation_status = cs_searchable
      expect(manifestation).not_to be_non_searchable

      update_system_configuration('manifestation.manage_item_rank', true) # manage_item_rankする
      # (2)+item.rankが2 -- 所定の条件を満たさない
      expect(manifestation).to be_non_searchable

      # (2)+item.rankが1 -- 条件を満たす
      item.rank = 1
      expect(manifestation).not_to be_non_searchable
    end
  end

  describe '#has_removed?' do
    it 'circulation_statusが "Removed" である所蔵があればtrueを返すこと' do
      rp = FactoryGirl.create(
        :retention_period,
        name: 'has_removed_test')

      manifestation = FactoryGirl.create(:manifestation)
      expect(manifestation).not_to be_has_removed

      item1 = manifestation.items.build(
        manifestation: manifestation,
        circulation_status: cs_in_factory,
        retention_period: rp)
      item1.save!
      expect(manifestation).not_to be_has_removed

      item2 = manifestation.items.build(
        manifestation: manifestation,
        circulation_status: cs_removed,
        retention_period: rp)
      item2.save!
      expect(manifestation).to be_has_removed

      manifestation.items -= [item1]
      expect(manifestation).to be_has_removed

      manifestation.items -= [item2]
      expect(manifestation).not_to be_has_removed
    end
  end

  describe '#available_checkout_types' do
    it '' # TODO: immediately
  end

  describe '#new_serial?' do
    it '' # TODO
  end

  describe '#in_basket?' do
    it '' # TODO: immediately
  end

  describe '#checkout_period' do 
    it '' # TODO
  end

  describe '#reservation_expired_period' do
    it '' # TODO: immediately　EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#agents' do
    it '' # TODO
  end

  describe '#reservable_with_item?' do
    it '' # TODO EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#reservable?' do
    it '' # TODO EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#in_process?' do
    it '' # TODO
  end

  describe '#checkouts' do
    it '' # TODO EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#creator' do
    it '' # TODO
  end

  describe '#contributor' do
    it '' # TODO
  end

  describe '#publisher' do
    it '' # TODO
  end

  describe '.pickup' do
    it '' # TODO
  end

  describe '#extract_text' do
    it '' # TODO
  end

  describe '#created' do
    it '' # TODO
  end

  describe '#realized' do
    it '' # TODO
  end

  describe '#produced' do
    it '' # TODO
  end

  describe '#sort_title' do
    it '' # TODO
  end

  describe '#classifications' do
    it '' # TODO
  end

  describe '#questions' do
    it '' # TODO
  end

  describe '#web_item' do
    it '' # TODO
  end

  describe '#index_series_statement' do
    it '' # TODO
  end

  describe '#set_series_statement' do
    it '' # TODO
  end

  describe '#uniq_options' do
    it '' # TODO
  end

  describe '#reserve_coun' do
    it '' # TODO EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#checkout_count' do
    it '' # TODO EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#next_item_for_retain' do
    it '' # TODO EnjuTrunkCirculation使用時のみ利用可能とすべきでは？
  end

  describe '#items_ordered_for_retain' do
    it '' # TODO
  end

  describe '#ordered?' do
    it '' # TODO
  end

  describe '#add_subject' do
    it '' # TODO: immediately
  end

  describe '.build_search_for_manifestations_list' do
    it '' # TODO
  end

  describe '.generate_manifestation_list' do
    it '' # TODO: immediately
  end

  describe '.generate_manifestation_list_internal' do
    it '' # TODO: immediately
  end

  describe '.get_manifestation_list_excelx' do
    it '' # TODO: immediately
  end

  describe '#excel_worksheet_value' do
    it '' # TODO: immediately
  end

  describe '.get_missing_issue_list_pdf' do
    it '' # TODO
  end

  describe '.get_manifestation_list_pdf(' do
    it '' # TODO
  end

  describe '.get_manifestation_list_tsv' do
    it '' # TODO
  end

  describe '.get_manifestation_locate' do
    it '' # TODO
  end


# 以下、元のテスト
  it "should set pub_date" do
    manifestation = FactoryGirl.create(:manifestation, :pub_date => '2000')
    manifestation.date_of_publication.should eq Time.zone.parse('2000-12-31').end_of_month
  end

  it "should set number from serial_number_string" do
    manifestation = FactoryGirl.create(:manifestation, :serial_number_string => '通号29号')
    manifestation.serial_number.should eq 29
  end

  it "should set volume from volume_number_string" do
    manifestation = FactoryGirl.create(:manifestation, :volume_number_string => '第29巻')
    manifestation.volume_number.should eq 29
  end

  it "should clear volume_number (over limit length)" do
    manifestation = FactoryGirl.create(:manifestation, :volume_number_string => '第29/30巻(第2部門 講義 1919-44)')
    manifestation.volume_number.should be_nil
  end

  it "should search title in openurl" do
    openurl = Openurl.new({:title => "プログラミング"})
    results = openurl.search
    openurl.query_text.should eq "btitle_text:プログラミング"
    results.size.should eq 8
    openurl = Openurl.new({:jtitle => "テスト"})
    results = openurl.search
    results.size.should eq 2
    openurl.query_text.should eq "jtitle_text:テスト"
    openurl = Openurl.new({:atitle => "2005"})
    results = openurl.search
    results.size.should eq 1
    openurl.query_text.should eq "atitle_text:2005"
    # 全角半角が判定できていないため以下の文はエラー判定になる
    openurl = Openurl.new({:atitle => "テスト", :jtitle => "2月号"})
    results = openurl.search
    results.size.should eq 1
  end

  it "should search agent in openurl" do
    openurl = Openurl.new({:aulast => "Administrator"})
    results = openurl.search
    openurl.query_text.should eq "au_text:Administrator"
    results.size.should eq 2
    openurl = Openurl.new({:aufirst => "名称"})
    results = openurl.search
    openurl.query_text.should eq "au_text:名称"
    results.size.should eq 1
    openurl = Openurl.new({:au => "テスト"})
    results = openurl.search
    openurl.query_text.should eq "au_text:テスト"
    results.size.should eq 1
    openurl = Openurl.new({:pub => "Administrator"})
    results = openurl.search
    openurl.query_text.should eq "publisher_text:Administrator"
    results.size.should eq 4
  end

  it "should search isbn in openurl" do
    openurl = Openurl.new({:api => "openurl", :isbn => "4798"})
    results = openurl.search
    openurl.query_text.should eq "isbn_sm:4798*"
    results.size.should eq 2
  end

  it "should search issn in openurl" do
    openurl = Openurl.new({:api => "openurl", :issn => "1234"})
    results = openurl.search
    openurl.query_text.should eq "issn_s:1234*"
    results.size.should eq 2
  end

  it "should search any in openurl" do
    openurl = Openurl.new({:any => "テスト"})
    results = openurl.search
    results.size.should eq 9
  end

  it "should serach multi in openurl" do
    openurl = Openurl.new({:btitle => "CGI Perl プログラミング"})
    results = openurl.search
    results.size.should eq 3
    openurl = Openurl.new({:jtitle => "テスト", :pub => "テスト"})
    results = openurl.search
    results.size.should eq 2
  end

  it "shoulld get search_error in openurl" do
    lambda{Openurl.new({:isbn => "12345678901234"})}.should raise_error(OpenurlQuerySyntaxError)
    lambda{Openurl.new({:issn => "1234abcd"})}.should raise_error(OpenurlQuerySyntaxError)
    lambda{Openurl.new({:aufirst => "テスト 名称"})}.should raise_error(OpenurlQuerySyntaxError)
  end

  it "should search in sru" do
    sru = Sru.new({:query => "title=Ruby"})
    sru.search
    sru.manifestations.size.should eq 18
    sru.manifestations.first.titles.first.should eq 'Ruby'
    sru = Sru.new({:query => "title=^ruby"})
    sru.search
    sru.manifestations.size.should eq 9
    sru = Sru.new({:query => 'title ALL "awk sed"'})
    sru.search
    sru.manifestations.size.should eq 2
    sru.manifestations.collect{|m| m.id}.should eq [184, 116]
    sru = Sru.new({:query => 'title ANY "ruby awk sed"'})
    sru.search
    sru.manifestations.size.should eq 22
    sru = Sru.new({:query => 'isbn=9784756137470'})
    sru.search
    sru.manifestations.first.id.should eq 114
    sru = Sru.new({:query => "creator=テスト"})
    sru.search
    sru.manifestations.size.should eq 1
  end

  it "should search date in sru" do
    sru = Sru.new({:query => "from = 2000-09 AND until = 2000-11-01"})
    sru.search
    sru.manifestations.size.should eq 1
    sru.manifestations.first.id.should eq 120
    sru = Sru.new({:query => "from = 1993-02-24"})
    sru.search
    sru.manifestations.size.should eq 5
    sru = Sru.new({:query => "until = 2006-08-06"})
    sru.search
    sru.manifestations.size.should eq 4
  end

  it "should accept sort_by in sru" do
    sru = Sru.new({:query => "title=Ruby"})
    sru.sort_by.should eq({:sort_by => 'created_at', :order => 'desc'})
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title/sort.ascending"', :sortKeys => 'creator,0', :version => '1.2'})
    sru.sort_by.should eq({:sort_by => 'sort_title', :order => 'asc'})
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title/sort.ascending"', :sortKeys => 'creator,0', :version => '1.1'})
    sru.sort_by.should eq({:sort_by => 'creator', :order => 'desc'})
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title/sort.ascending"', :sortKeys => 'creator,1', :version => '1.1'})
    sru.sort_by.should eq({:sort_by => 'creator', :order => 'asc'})
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title'})
    sru.sort_by.should eq({:sort_by => 'sort_title', :order => 'asc'})
    #TODO ソート基準が入手しやすさの場合の処理
  end

  it "should accept rangs in sru" do
    sru = Sru.new({:query => "from = 1993-02-24 AND until = 2006-08-06 AND title=プログラミング"})
    sru.search
    sru.manifestations.size.should eq 2
    sru = Sru.new({:query => "until = 2000 AND title=プログラミング"})
    sru.search
    sru.manifestations.size.should eq 1
    sru = Sru.new({:query => "from = 2006 AND title=プログラミング"})
    sru.search
    sru.manifestations.size.should eq 1
    sru = Sru.new({:query => "from = 2007 OR title=awk"})
    sru.search
    sru.manifestations.size.should eq 6
  end

  it "should be reserved" do
    manifestations(:manifestation_00007).is_reserved_by(users(:admin)).should be_true
  end

  it "should not be reserved" do
    manifestations(:manifestation_00007).is_reserved_by(users(:user1)).should be_nil
  end

  it "should_get_number_of_pages" do
    manifestations(:manifestation_00001).number_of_pages.should eq 100
  end

  it "should get youtube_id" do
    manifestations(:manifestation_00022).youtube_id.should eq 'BSHBzd9ftDE'
  end

  it "should get nicovideo_id" do
    manifestations(:manifestation_00023).nicovideo_id.should eq 'sm3015373'
  end

  it "should have parent_of_series" do
    manifestations(:manifestation_00001).parent_of_series.should be_true
  end

  it "should respond to extract_text" do
    manifestations(:manifestation_00001).extract_text.should be_nil
  end

  it "should not be reserved it it has no item" do
    #TODO: system_configatronの設定によって条件変化
    #manifestations(:manifestation_00008).reservable?.should be_false
  end

  it "should respond to title" do
    manifestations(:manifestation_00001).title.should be_true
  end

  it "should import isbn" do
    Manifestation.import_isbn('4797327030').should be_valid
  end

  it "should respond to pickup" do
    Manifestation.pickup.should_not raise_error(ActiveRecord::RecordNotFound)
  end

  describe '.searchは' do
    subject { Manifestation }

    let(:exact_word) { 'アジャイル' }
    let(:typo_word)  { 'アジイャル' }
    let(:exact_title) { "Railsによる#{exact_word}Webアプリケーション開発" }
    let(:typo_title)  { "Railsによる#{typo_word }Webアプリケーション開発" }

    let(:search_spec) do
      proc {
        fulltext exact_title
      }
    end

    before do
      Sunspot.remove_all!

      @manifestation_type = FactoryGirl.create(:manifestation_type)
      @manifestation = FactoryGirl.create(
        :manifestation,
        :original_title => exact_title,
        :manifestation_type => @manifestation_type)

      Sunspot.commit
    end

    def do_test_search
      @result = subject.search(&search_spec).execute
    end

    it '書名により検索できること' do
      do_test_search

      @result.results.should have(1).item
      @result.results.first.should == @manifestation

      @result.raw_suggestions.should be_nil
      @result.suggestions.should be_nil
      @result.collation.should be_nil
    end

    shared_examples_for '「もしかして」検索' do
      it '「もしかして」検索ができること' do
        do_test_search

        @result.results.should have(:no).items

        raw = @result.raw_suggestions
        raw.should be_a(Array)
        raw.each_slice(2).to_a.assoc(typo_word).should be_present

        sug = @result.suggestions
        sug.should be_a(Hash)
        sug.should be_include(typo_word)
        sug[typo_word].should == [exact_word]
      end
    end

    context 'spellcheck指定があるとき' do
      let(:search_spec) do
        proc {
          fulltext typo_title
          spellcheck
        }
      end
      include_examples '「もしかして」検索'

      it 'collationを返さないこと' do
        do_test_search
        @result.collation.should be_nil
      end
    end

    context 'spellcheck collate指定があるとき' do
      let(:search_spec) do
        proc {
          fulltext typo_title
          spellcheck collate: true
        }
      end
      include_examples '「もしかして」検索'

      it 'collationを返すこと' do
        do_test_search
        @result.collation.should be_present
        @result.collation.first.should == exact_title
      end
    end

    context 'spellcheck collate=>3指定があるとき' do
      before do
        [
          'JRuby on Rails実践開発ガイド',
          '実践Ruby on Rails Webプログラミング入門 : 無駄なく迅速な開発環境 : Webアプリケーション開発を加速するJavaエンジニアのためのRoR入門!',
          'はじめてのGrails : 「Ruby on Rails」風の「フレームワーク」をJavaで使いこなす!',
        ].each do |title|
          FactoryGirl.create(
            :manifestation,
            :original_title => title,
            :manifestation_type => @manifestation_type)
        end
        Sunspot.commit
      end

      let(:search_spec) do
        proc {
          fulltext 'ruy on rails'
          spellcheck collate: 3
        }
      end

      it 'collationを複数返すこと' do
        do_test_search
        @result.collation.should be_present
        @result.collation.count.should > 1
      end
    end
  end

  describe '#searchableブロックは' do
    before do
      # NOTE:
      # 2013-01-15現在、
      # spec/fixtures/series_has_manifestations.yml中で
      # series_statement_idに1、2、3が設定されているのに対し、
      # spec/fixtures/series_statements.ymlでは
      # idが1、2のレコードしか記述されていない。
      # このため、fixtureのロード後に作成した
      # SeriesStatmentレコードに意図しない
      # Manifestationレコードが関連付けられてしまう。
      #
      # 以下で、こうした混乱を避けるために
      # 空のSeriesStatmentを作成する。
      10.times { FactoryGirl.create(:series_statement) }
    end

    def setup_manifestations_for_search
      @series_statement =
        case series_statement_type
        when :periodical
          # 雑誌
          FactoryGirl.create(:series_statement, :periodical => true)
        when true
          # 定期刊行物
          FactoryGirl.create(:series_statement, :periodical => false)
        when false
          # 書誌
          nil
        end

      manifestation_type = FactoryGirl.create(:manifestation_type)

      @manifestations = [
        @manifestation1 = FactoryGirl.create(
          :manifestation,
          :manifestation_type => manifestation_type,
          :series_statement => @series_statement,
          :isbn => '9784010000007',
          :isbn10 => '4010000007',
          :wrong_isbn => '978401000000X',
          :issn => '10000003',
          :date_of_publication => Date.new(1001, 1, 1),
          :start_page => 1,
          :end_page => 100766),
        @manifestation2 = FactoryGirl.create(
          :manifestation,
          :manifestation_type => manifestation_type,
          :series_statement => @series_statement,
          :isbn => '9784020000004',
          :isbn10 => '402000000X',
          :wrong_isbn => '978402000000X',
          :issn => '20000006',
          :date_of_publication => Date.new(1002, 1, 1),
          :start_page => 1,
          :end_page => 200467),
        @manifestation3 = FactoryGirl.create( # 対比用のダミー
          :manifestation,
          :manifestation_type => manifestation_type,
          :series_statement => nil,
          :isbn => '9784030000001',
          :isbn10 => '4030000002',
          :wrong_isbn => '978403000000X',
          :issn => '30000009',
          :date_of_publication => Date.new(1003, 1, 1),
          :start_page => 1,
          :end_page => 300918),
      ]

      if @series_statement # 雑誌(@manifestation1をroot_manifestationとする)
        @series_statement.root_manifestation = @manifestation1
        @series_statement.save!
      end
    end

    shared_examples_for 'Solrインデックスへの登録' do
      before :each do
        Sunspot.remove_all!

        setup_manifestations_for_search
      end

      # Manifestation.searchableで正しくインデックス登録されることを検証する。
      #
      # なおextract_keys_methodで導出される検索語および
      # それを用いたsearch_methodにより構成される検索条件により、
      # ただ一つのmanifestationを特定できることを前提としている。
      # (雑誌のmanifestationの場合は検索語により特定されるのとは別に
      # そのmanifestationのroot manifestationも検出されるが、
      # 検索語により特定されるのが一つであればこの前提には十分であるあ)
      #
      # extract_keys_method: インデックスに登録されることを検証するための検索で指定する値を導くメソッド(シンボルまたはprocで、前者ならばManifestationレコードにsendされ、後者ならばManifestationレコードとともにyieldされる)
      # search_method: Manifestation.searchで検索条件を指定するのに使うメソッド(およびその引数)
      # prepared_keys: 検証のために用意したテスト用属性データ(オブジェクト)群
      # not_collect_series_attrs: 雑誌であっても、同誌書誌群の情報を収集しないインデックス項目の場合にtrueを指定する(creator、isbnなどはfalse、connect_creator、non_searchableなどはtrue)
      #
      # ブロックには、用意された属性データから
      # インデックスに登録されているはずの検索語(など)を
      # 取り出す処理を与える。
      def it_should_search_items_by_attr(extract_keys_method, *search_method, prepared_keys, not_collect_series_attrs, &block)
        Sunspot.commit

        @manifestations.each do |manifestation|
          if manifestation.series_statement.blank? ||
              series_statement_type != :periodical ||
              not_collect_series_attrs
            # manifestationが雑誌でなかったとき
            # または雑誌であっても同雑誌の情報を集めべきインデックス項目のテストのとき
            expect = [manifestation]

          else
            # manifestationが雑誌であったとき
            #
            # NOTE:
            # manifestationの一部属性値については
            # 同雑誌(SeriesStatement)に属する全レコードの属性値を
            # 集約したものがroot_manifestationの値として
            # インデックスに格納される。
            # すなわち、root_manifestation(root_of_series?がtrue)である
            # manifestationが更新される際には
            # 同雑誌の他のmanifestationの属性値を集約する。
            #
            # ここで、同雑誌のmanifestationとして
            # A、B、Cの順に登録されたとすると、
            # 通常、Aがroot_manifestationとなる。
            # そしてAには将来的にB、Cの属性値が集約される
            # (つまりB、Cの属性値を指定した検索すると
            # Aも検索結果に出現する)ことになる。
            # ただし、最初にAが登録される時点では
            # B、Cは存在しないため、属性値としては
            # A自身の属性値だけが使用される。
            # 続いてB、Cが登録されるときには
            # それぞれに対してそれぞれ自身の
            # 属性値が使用される。
            # B、Cが登録された後にAが更新されると、
            # そのタイミングでAの値としてB、Cの属性値が
            # Aに関連付けられる形でインデックスが更新される。
            if manifestation.root_of_series?
              expect = [manifestation]

            else
              root_manifestation = @manifestation1
              if root_manifestation.updated_at > manifestation.created_at
                # root_manifestationが、他のmanifestationの登録より後に更新されている
                # (root_manifestationには他manifestationの属性値が関連付けられている)
                expect = [root_manifestation, manifestation]
              else
                # root_manifestationが、それ自身の登録以降更新されていない
                # (root_manifestationには他manifestationの属性値が関連付けられていない)
                expect = [manifestation]
              end
            end
          end

          # 検証のための検索に与える検索キー(検索条件)を取り出す
          keys = if extract_keys_method.is_a?(Proc)
                   extract_keys_method.call(manifestation)
                 else
                   manifestation.__send__(extract_keys_method)
                 end
          keys = [keys] unless keys.respond_to?(:each)

          # 各検索キーで実際に検索してみる
          keys.each do |key|
            prepared_keys -= [key]

            results = Manifestation.search do
              __send__(*search_method, block ? block.call(key) : key)
            end.results

            results.should have(expect.count).items,
              "expected #{expect.count} items for '#{search_method.join(' ')}' search with #{search_key_record_inspect(key)}, got #{results.count} items"
            (results - expect).should be_empty
          end
        end # @manifestations.each

        # 検索キーとして使われなかった属性データは
        # インデックスに登録されていないはずのものである。
        # 最後に、たしかにインデックスに登録されていないことを検証する。
        prepared_keys.each do |key|
          results = Manifestation.search do
            __send__(*search_method, block ? block.call(key) : key)
          end.results
          results.should have(:no).items,
            "expected no items for '#{search_method.join(' ')}' search with #{search_key_record_inspect(key)}, got #{results.count} items"
        end
      end

      def search_key_record_inspect(obj)
        case obj
        when Agent; "agent '#{obj.full_name}'"
        else; obj
        end
      end

      def it_should_search_items_by_agent(reader)
        setter = :"#{reader}="

        agents = [
          @agent1 = FactoryGirl.create(:agent, :full_name => 'あいうえお'),
          @agent2 = FactoryGirl.create(:agent, :full_name => 'かきくけこ'),
          @agent3 = FactoryGirl.create(:agent, :full_name => 'さしすせそ'),
          @agent4 = FactoryGirl.create(:agent, :full_name => 'たちつてと'),
          @agent5 = FactoryGirl.create(:agent, :full_name => 'なにぬねの'),
        ]

        emulate_static = proc do |m|
          if ENV['ENABLE_ITEM_ATTR_CACHE']
            # NOTE:
            # ManifestationのItem属性値内部キャッシュは
            # 動作中にレコードの状態が変わらないことを前提としている。
            # 通常これはrakeタスクによる
            # インデックス再構築のときにだけ有効な前提である。
            # (DBから読み取ったママをインデックスに登録するのみ。)
            #
            # 本テストにおいては環境変数ENABLE_ITEM_ATTR_CACHEが
            # 設定されているときに限り、
            # インデックス登録が完全に行われた状態を
            # エミュレートするために、特別に、
            # テストで使用するManifestationレコードの
            # 最新の状態をもとに改めてインデックス登録を行う。
            #
            # なお、本テストではインデックス登録のタイミングの違いによる
            # ある種のインデックスの不整合
            # (it_should_search_items_by_attrのNOTEを参照)
            # を含めて検証している。
            # このためreloadとindexは
            # レコードに変更を加えた直後に
            # いちいち実施する必要がある。
            m.reload
            m.index
          end
        end

        @manifestation1.__send__(setter, [@agent1])
        @manifestation1.tap(&emulate_static)
        @manifestation2.__send__(setter, [@agent2, @agent3])
        @manifestation2.tap(&emulate_static)
        @manifestation3.__send__(setter, [@agent4])
        @manifestation3.tap(&emulate_static)

        it_should_search_items_by_attr(reader, :fulltext, agents, false) do |obj|
          obj.full_name
        end
      end

      it '著者をインデックスに登録すること' do
        it_should_search_items_by_agent(:creators)
      end

      it '出版社をインデックスに登録すること' do
        it_should_search_items_by_agent(:publishers)
      end

      it 'ISBNをインデックスに登録すること' do
        isbn13 = %w(
          9784010000007
          9784020000004
          9784030000001
          9784090000003
        )
        isbn10 = %w(
          4010000007
          402000000X
          4030000002
          4090000009
        )
        wrong_isbn = %w(
          978401000000X
          978402000000X
          978403000000X
          978409000000X
        )

        it_should_search_items_by_attr(:isbn, :with, :isbn, isbn13, false)
        it_should_search_items_by_attr(:isbn, :fulltext, isbn13, false)

        it_should_search_items_by_attr(:isbn10, :with, :isbn, isbn10, false)
        it_should_search_items_by_attr(:isbn10, :fulltext, isbn10, false)

        it_should_search_items_by_attr(:wrong_isbn, :with, :isbn, wrong_isbn, false)
        it_should_search_items_by_attr(:wrong_isbn, :fulltext, wrong_isbn, false)
      end

      it 'ISSNをインデックスに登録すること' do
        issn = %w(
          10000003
          20000006
          30000009
          90000005
        )

        it_should_search_items_by_attr(:issn, :with, :issn, issn, false)
        it_should_search_items_by_attr(:issn, :fulltext, issn, false)
      end

      it '出版日をインデックスに登録すること' do
        pub_date = [
          Date.new(1001, 1, 1),
          Date.new(1002, 1, 1),
          Date.new(1003, 1, 1),
          Date.new(1009, 1, 1),
        ]

        it_should_search_items_by_attr(
          :date_of_publication,
          :with, :pub_date,
          pub_date, false)
      end

      it 'ページ数をインデックスに登録すること' do
        number_of_pages = [
          100766,
          200467,
          300918,
          900235,
        ]

        it_should_search_items_by_attr(
          :number_of_pages,
          :with, :number_of_pages,
          number_of_pages, false
        )
      end

      describe '所蔵群の' do
        before do
          rp_in_factory = FactoryGirl.create(:retention_period, name: 'In Factory')
          rp_other = FactoryGirl.create(:retention_period, name: 'other')

          shelf1 = shelves(:shelf_00001) # shelf1.library #=> library_00001
          shelf2 = shelves(:shelf_00002) # shelf2.library #=> library_00002
          shelf3 = shelves(:shelf_00003) # shelf3.library #=> library_00002
          shelf4 = shelves(:shelf_00004) # shelf4.library #=> library_00003

          @item_spec = {
            @manifestation1 => [
              {
                item_identifier: 'item11',
                acquired_at: Time.zone.local(1001, 1, 10),
                removed_at: Time.zone.local(1001, 1, 15),
                shelf: shelf1,
                circulation_status: cs_removed,
                retention_period: rp_other,
              },
            ],
            @manifestation2 => [
              {
                item_identifier: 'item21',
                acquired_at: Time.zone.local(1002, 1, 10),
                removed_at: Time.zone.local(1002, 1, 15),
                shelf: shelf2,
                circulation_status: cs_available,
                retention_period: rp_other,
              },
              {
                item_identifier: 'item22',
                acquired_at: Time.zone.local(1002, 2, 10),
                removed_at: Time.zone.local(1002, 2, 15),
                shelf: shelf3,
                circulation_status: cs_in_process,
                retention_period: rp_in_factory,
              },
              {
                item_identifier: 'item23',
                acquired_at: Time.zone.local(1002, 3, 10),
                removed_at: Time.zone.local(1002, 3, 15),
                shelf: shelf3,
                circulation_status: cs_removed,
                retention_period: rp_other,
              },
            ],
            @manifestation3 => [
              {
                item_identifier: 'item31',
                acquired_at: Time.zone.local(1003, 1, 10),
                removed_at: Time.zone.local(1003, 1, 15),
                shelf: shelf4,
                circulation_status: cs_removed,
                retention_period: rp_other,
              },
              {
                item_identifier: 'item32',
                acquired_at: Time.zone.local(1003, 2, 10),
                removed_at: Time.zone.local(1003, 2, 15),
                shelf: shelf4,
                circulation_status: cs_removed,
                retention_period: rp_other,
              },
            ],
          }

          @item_spec.each do |manifestation, spec|
            spec.each do |s|
              item = Item.new(
                item_identifier: s[:item_identifier],
                manifestation: manifestation,
                shelf: s[:shelf],
                circulation_status: s[:circulation_status],
                retention_period: s[:retention_period]
              )
              item.acquired_at = s[:acquired_at]
              item.removed_at = s[:removed_at]
              item.save!
            end
            manifestation.reload if ENV['ENABLE_ITEM_ATTR_CACHE'] # NOTE: it_should_search_items_by_agentのNOTEを参照
            manifestation.index # itemsが変化しているのをsolrに伝える
          end
          after_setup_items_hook.call if defined?(after_setup_items_hook)
        end

        it '所蔵情報IDをインデックスに登録すること' do
          item_identifier = 
            @item_spec.values.flatten.map {|h| h[:item_identifier] }

          it_should_search_items_by_attr(
            proc {|manifestation| @item_spec[manifestation].map {|h| h[:item_identifier] } },
            :with, :item_identifier,
            item_identifier, false
          )
        end

        it '除籍日をインデックスに登録すること' do
          removed_at = 
            @item_spec.values.flatten.map {|h| h[:removed_at] }

          it_should_search_items_by_attr(
            proc do |manifestation|
              @item_spec[manifestation].map do |h|
                h[:circulation_status] == cs_removed ? h[:removed_at] : nil
              end.compact
            end,
            :with, :removed_at,
            removed_at, false
          )
        end

        it 'それぞれの最古の受入日をインデックスに登録すること' do
          acquired_at =
            @item_spec.values.flatten.map {|h| h[:acquired_at] }

#XXX: acquired_at_smで確認せよ?
          it_should_search_items_by_attr(
            proc {|manifestation| @item_spec[manifestation].map {|h| h[:acquired_at] }.min },
            :with, :acquired_at,
            acquired_at, false
          )
        end

        it '図書館名をインデックスに登録すること' do
          library =
            @item_spec.values.flatten.map {|h| h[:shelf].library.name }

          it_should_search_items_by_attr(
            proc {|manifestation| @item_spec[manifestation].map {|h| h[:shelf].library.name } },
            :with, :library,
            library, true
          )
        end

        it '棚名をインデックスに登録すること' do
          shelf =
            @item_spec.values.flatten.map do |h|
              "#{h[:shelf].library.name}_#{h[:shelf].name}"
            end

          it_should_search_items_by_attr(
            proc do |manifestation|
              @item_spec[manifestation].map do |h|
                "#{h[:shelf].library.name}_#{h[:shelf].name}"
              end
            end,
            :with, :shelf,
            shelf, true
          )
        end

        it 'circulation_statusが "In Process" であるものを含むかどうかを登録すること' do
          q_fmt = "id_i:%d %s circulation_status_in_process_b:true"

          cs_and_manifestation_id = @item_spec.keys.map do |manifestation|
            %w(AND NOT).map {|op| q_fmt%[manifestation.id, op] }
          end.flatten

          it_should_search_items_by_attr(
            proc do |manifestation|
              if @item_spec[manifestation].any? {|h| h[:circulation_status].name == 'In Process' }
                op = 'AND'
              else
                op = 'NOT'
              end
              q_fmt%[manifestation.id, op]
            end,
            :fulltext,
            cs_and_manifestation_id, true
          )
        end

        it 'circulation_statusが "In Factory" であるものを含むかどうかを登録すること' do
          q_fmt = "id_i:%d %s circulation_status_in_factory_b:true"

          cs_and_manifestation_id = @item_spec.keys.map do |manifestation|
            %w(AND NOT).map {|op| q_fmt%[manifestation.id, op] }
          end.flatten

          it_should_search_items_by_attr(
            proc do |manifestation|
              if @item_spec[manifestation].any? {|h| h[:circulation_status].name == 'In Factory' }
                op = 'AND'
              else
                op = 'NOT'
              end
              q_fmt%[manifestation.id, op]
            end,
            :fulltext,
            cs_and_manifestation_id, true
          )
        end
      end

      if defined?(EnjuBookmark)
        it 'タグをインデックスに登録すること' do
          tag_list = [
            'foo',
            'bar,baz',
            'quux',
            'empty',
          ]
          prepared_tags = []
          [
            @manifestation1, @manifestation2, @manifestation3
          ].each_with_index do |manifestation, i|
            user = FactoryGirl.create(:user)
            url = "http://example.jp/#{i}"

            manifestation.access_address = url # NOTE: manifestationがブックマーク追加により自動生成されるのを回避する
            manifestation.save!

            bookmark = manifestation.bookmarks.build(
              :title => "bookmark title #{i}",
              :url => url,
              :tag_list => tag_list[i]
            )
            bookmark.user = user
            bookmark.save!

            prepared_tags << bookmark.tags

            # NOTE
            # bookmark追加によりmanifestationの
            # 再インデックスが必要そうなのだが、
            # そのようになっていないため
            # ここで明示的に再インデックスする
            manifestation.index!
          end

          it_should_search_items_by_attr(
            :tags,
            :with, :tag,
            prepared_tags.flatten, false
          ) {|obj| obj.name }

          it_should_search_items_by_attr(
            :tags,
            :fulltext,
            prepared_tags.flatten, false
          ) {|obj| obj.name }
        end
      end
    end

    describe '書誌について' do
      let :series_statement_type do
        false
      end
      include_examples 'Solrインデックスへの登録'
    end

    describe '定期刊行物について' do
      let :series_statement_type do
        true
      end
      include_examples 'Solrインデックスへの登録'
    end

    describe '雑誌について' do
      let :series_statement_type do
        :periodical
      end
      include_examples 'Solrインデックスへの登録'
    end

    describe '雑誌のroot_manifestationが最後に更新されたとき、同雑誌の他のmanifestationおよび自身の' do
      let :series_statement_type do
        :periodical
      end
      let :after_setup_items_hook do
        # 所蔵を登録した後で、root_manifestationに
        # 他manifestationの属性値を関連付ける
        # (全所蔵の最新情報を収集しなおす)ために、
        # root_manifestationを強制更新しておく
        proc do
          @manifestation1.updated_at += 10
          @manifestation1.save!
        end
      end
      include_examples 'Solrインデックスへの登録'
    end
  end

  describe '.create_from_ncidは' do
    include NacsisCatSpecHelper

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
    end

    it '指定されたNCIDからレコードを作成すること' do
      nacsis_cat = nacsis_cat_with_mock_record
      ncid = nacsis_cat.ncid
      NacsisCat.should_receive(:search) do |opts|
        expect(opts[:dbs]).to eq([:book])
        expect(opts[:id]).to eq(ncid)
        {book: [nacsis_cat]}
      end

      m = Manifestation.create_from_ncid(ncid)
      expect(m).to be_a(Manifestation)

      expect(m.nacsis_identifier).to eq(ncid)
      expect(m.original_title).to eq(nacsis_cat.record['TR']['TRD'])
      expect(m.title_transcription).to eq(nacsis_cat.record['TR']['TRR'])
      expect(m.title_alternative).to eq(nacsis_cat.record['TR']['TRVR'])

      expect(m).to be_persisted
    end

    it '指定されたNCIDに対応するレコードが見付からなかったら空のレコードを返すこと' do
      ncid = 'foobar'
      NacsisCat.should_receive(:search).and_return({book: []})

      m = Manifestation.create_from_ncid(ncid)
      expect(m).to be_a_new(Manifestation)

      expect(m.nacsis_identifier).to eq(ncid)
      expect(m.original_title).to be_blank
      expect(m.title_transcription).to be_blank
      expect(m.title_alternative).to be_blank
    end
  end

  describe '.batch_create_from_ncidは' do
    include NacsisCatSpecHelper

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
    end

    it '指定されたNCIDからレコードを作成すること' do
      nacsis_cat = nacsis_cat_with_mock_record
      ncid = nacsis_cat.ncid
      NacsisCat.should_receive(:search) do |opts|
        expect(opts[:dbs]).to eq([:book])
        expect(opts[:id]).to eq([ncid])
        {book: [nacsis_cat]}
      end

      expect {
        Manifestation.batch_create_from_ncid([ncid])
      }.to change(Manifestation, :count).by(1)

      m = Manifestation.last
      expect(m).to be_present
      expect(m).to be_a(Manifestation)

      expect(m.nacsis_identifier).to eq(ncid)
      expect(m.original_title).to eq(nacsis_cat.record['TR']['TRD'])
      expect(m.title_transcription).to eq(nacsis_cat.record['TR']['TRR'])
      expect(m.title_alternative).to eq(nacsis_cat.record['TR']['TRVR'])

      expect(m).to be_persisted
    end

    it '指定されたNCIDに対応するレコードが見付からなかったらレコードを作成しないこと' do
      ncid = 'foobar'
      NacsisCat.should_receive(:search).and_return({book: []})

      expect {
        Manifestation.batch_create_from_ncid([ncid])
      }.not_to change(Manifestation, :count)
    end
  end

  context 'use EnjuBookmark' do
    describe 'search' do
      it '' # TODO
    end

    describe '#bookmarked?' do
      it '' # TODO
    end

    describe '#tags' do
      it '' # TODO
    end
  end
end

=begin
  describe GenerateManifestationListJob do
    describe '#initialize' do
      it '' # TODO
    end

    describe '#perform' do
      it '' # TODO
    end
  end
=end

# == Schema Information
#
# Table name: manifestations
#
#  id                              :integer         not null, primary key
#  original_title                  :text            not null
#  title_alternative               :text
#  title_transcription             :text
#  classification_number           :string(255)
#  identifier                      :string(255)
#  date_of_publication             :datetime
#  date_copyrighted                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  deleted_at                      :datetime
#  access_address                  :string(255)
#  language_id                     :integer         default(1), not null
#  carrier_type_id                 :integer         default(1), not null
#  extent_id                       :integer         default(1), not null
#  start_page                      :integer
#  end_page                        :integer
#  height                          :decimal(, )
#  width                           :decimal(, )
#  depth                           :decimal(, )
#  isbn                            :string(255)
#  isbn10                          :string(255)
#  wrong_isbn                      :string(255)
#  nbn                             :string(255)
#  lccn                            :string(255)
#  oclc_number                     :string(255)
#  issn                            :string(255)
#  price                           :integer
#  fulltext                        :text
#  volume_number_list              :string(255)
#  issue_number_list               :string(255)
#  serial_number_list              :string(255)
#  edition                         :integer
#  note                            :text
#  produces_count                  :integer         default(0), not null
#  exemplifies_count               :integer         default(0), not null
#  embodies_count                  :integer         default(0), not null
#  work_has_subjects_count         :integer         default(0), not null
#  repository_content              :boolean         default(FALSE), not null
#  lock_version                    :integer         default(0), not null
#  required_role_id                :integer         default(1), not null
#  state                           :string(255)
#  required_score                  :integer         default(0), not null
#  frequency_id                    :integer         default(1), not null
#  subscription_master             :boolean         default(FALSE), not null
#  ipaper_id                       :integer
#  ipaper_access_key               :string(255)
#  attachment_file_name            :string(255)
#  attachment_content_type         :string(255)
#  attachment_file_size            :integer
#  attachment_updated_at           :datetime
#  nii_type_id                     :integer
#  title_alternative_transcription :text
#  description                     :text
#  abstract                        :text
#  available_at                    :datetime
#  valid_until                     :datetime
#  date_submitted                  :datetime
#  date_accepted                   :datetime
#  date_caputured                  :datetime
#  file_hash                       :string(255)
#  pub_date                        :string(255)
#  periodical_master               :boolean         default(FALSE), not null
#

