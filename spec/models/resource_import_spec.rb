# encoding: utf-8
require 'spec_helper'

describe ResourceImport do
  fixtures :languages, :countries, :carrier_types, :frequencies, :agents, :agent_types, :roles,
    :circulation_statuses, :checkout_types, :numberings

  def create_resource_import_textfile(file, adapter_name, textfile_params, external_resource)
    # 基本的にはResourceImportTextfilesController#createの動作を模倣する
    extraparams = {
      'sheet' => [],
      'manifestation_types' => [],
      'numbering' => [],
      'auto_numbering' => [],
      'not_set_serial_number' => [],
      'external_resource' => [],
    }
    [textfile_params].flatten.each_with_index do |params, i|
      params.each do |key, value|
        extraparams[key.to_s][i] = value
      end
      extraparams['external_resource'][i] = external_resource
    end

    ResourceImportTextfile.create(
      resource_import_text: file,
      adapter_name: adapter_name,
      extraparams: extraparams.to_s
    ).tap do |textfile|
      textfile.user = FactoryGirl.create(
        :librarian,
        user_group: FactoryGirl.create(:user_group)
      )
    end
  end

  def field_name(field_key, suffix = nil)
    if suffix
      ResourceImport::Sheet.suffixed_field_name(field_key, suffix)
    else
      ResourceImport::Sheet.field_name(field_key)
    end
  end

  # dataは各行の内容を集めた配列。
  #
  # 行の内容は次のいずれかの形式とする。
  #
  #   [ [key1, val1], [key2, val2],
  #     [[key3a, val3a_1], [key3b, val3b_1], [key3c, val3c_1]],
  #     [[key3a, val3a_2], [key3b, val3b_2], [key3c, val3c_1]],
  #     [key4, val4], ... ]
  #
  #   [ [key1, val1], [key2, val2],
  #     [key3a, [val3a_1, val3a_2]],
  #     [key3b, [val3b_1, val3b_2]],
  #     [key4, val4], ... ]
  #
  #   [ [key1, val1], [key2, val2],
  #     [key3a, val3a_1, val3a_2],
  #     [key3b, val3b_1, val3b_2],
  #     [key4, val4], ... ]
  def sheet_rows(data)
    column = {}
    row_data = []
    data.each do |d|
      row_data << row = {}
      d.each do |kv|
        if kv.first.is_a?(Array)
          raise ArgumentError unless kv.size == 2
          kv.each do |fk, val|
            row[fk] ||= []
            row[fk] << val
          end
        else
          fk, *vals = kv
          row[fk] = vals.flatten
        end
      end
      row.each do |fk, vals|
        column[fk] ||= 0
        column[fk] = vals.size if column[fk] < vals.size
      end
    end
    return [] if column.blank?

    spec = Manifestation.select_output_column_spec(:all)
    header = []
    row_data.inject([header]) do |rows, rd|
      rows << column.inject([]) do |row, (fk, n)|
        if spec[fk] == :singular
          header << field_name(fk) if rows.size == 1
          row << [rd[fk]].flatten.join(';')
        else
          1.upto(n) do |i|
            header << field_name(fk, i) if rows.size == 1
            row << rd[fk][i - 1]
          end
        end
        row
      end
    end
  end

  def create_one_line_textfile(row, sheet_params = {}, external_resource = 'ndl')
    sheet_name = sheet_params.delete(:sheet_name)
    sheet_name ||= 'test_sheet'
    create_textfile({sheet_name => [[row], sheet_params]}, external_resource)
  end

  def expect_to_be_success_result(results)
    expect(results).to be_present
    last_result = results.sort_by(&:created_at).last
    expect(last_result).to_not be_failed, 'expected success result, but not'
  end

  def expect_to_be_error_result(results)
    expect(results).to be_present
    last_result = results.sort_by(&:created_at).last
    expect(last_result).to be_failed, 'expected error result, but not'
  end

  def expect_to_include_error_result(results)
    expect(results).to be_present
    expect(results).to be_any {|r| r.failed },
      "expected to include error result, but not"
  end

  def expect_to_include_message(results, key, msg_opts = {})
    expect(results).to be_present
    msg = I18n.t("resource_import_textfile.#{key}", msg_opts)
    expect(results).to be_any {|r| r.error_msg.include?(msg) },
      "expected to include `#{msg}', but not"
  end

  def initialize_system_configuration(conf = {})
    add_system_configuration({
      'manifestations.split_by_type' => false,
      'set_output_format_type' => true, # true:tsv, false:csv
      'add_only_exist_agent' => true,
      'import_manifestation.use_delim' => true,
      'import_manifestation.exchange_series_statement' => false,
      # 以下はResourceImport外で参照されている設定
      'manifestation.isbn_unique' => true,
      'manifestation.use_item_has_operator' => false,
      'manifestation.manage_item_rank' => false,
      'agent.check_duplicate_user' => false,
      'auto_user_number' => false,
      'internal_server' => true,
    }.merge(conf))
    Manifestation.reinitialize_output_column_spec # システム設定manifestations.split_by_typeにより定義が変わるため再初期化が必要
  end

  let(:isbn1) { '9784010000007' }
  let(:isbn2) { '9784020000004' }
  let(:isbn3) { '9784030000001' }
  let(:issn1) { '0028-0836' }
  let(:issn2) { '0036-8075' }
  let(:issn3) { '0092-8674' }

  let(:japanese_book) do
    manifestation_type = FactoryGirl.create(
      :manifestation_type,
      name: 'japanese_book')
  end

  let(:japanese_magazine) do
    manifestation_type = FactoryGirl.create(
      :manifestation_type,
      name: 'japanese_magazine')
  end

  shared_examples_for 'インポート機能' do
    let(:logger) do
      [].tap do |obj|
        def obj.method_missing(sym, *args)
          Rails.logger.__send__(sym, *args)
          self << [sym, *args]
        end
      end
    end

    def prepare_manifestation
      @manifestation = FactoryGirl.create(
        :manifestation,
        original_title: 'test manifestation1',
        identifier: 'manifestation1',
        isbn: isbn1,
        pub_date: '2000',
        note: 'manifestation1 note',
        manifestation_type_id: japanese_book.id)
      @manifestation.reload
    end

    def prepare_items
      retention_period = FactoryGirl.create(
        :retention_period,
        name: 'permanent',
        display_name: '永年')

      @item = @manifestation.items.create!(
        item_identifier: 'item1',
        note: 'item1 note',
        retention_period: retention_period)
      @item.reload

      @item2 = @manifestation.items.create!(
        item_identifier: 'item2',
        note: 'item2 note',
        retention_period: retention_period)
      @item2.reload
    end

    def prepare_series_statement
      @series_statement = FactoryGirl.create(
        :series_statement,
        original_title: 'test series_statement1',
        series_statement_identifier: 'series_statement1',
        issn: issn1,
        periodical: false)
      @series_statement.reload

      @manifestation.manifestation_type = japanese_magazine
      @manifestation.save!
      @manifestation.series_statement = @series_statement
    end

    def prepare_root_manifestation
      @root_manifestation = @series_statement.initialize_root_manifestation
      @root_manifestation.original_title = 'test root manifestation1'
      @root_manifestation.identifier = 'root manifestation1'
      @root_manifestation.note = 'root manifestation1 note'
      @root_manifestation.manifestation_type = @manifestation.manifestation_type

      @root_manifestation.save!
      @series_statement.save!

      @root_manifestation.reload
    end

    def import_one_line_textfile(row, sheet_params = {}, external_resource = 'ndl', &block)
      @textfile = create_one_line_textfile(row, sheet_params, external_resource)
      subject.import(@textfile)
      if block
        block.call(@textfile.resource_import_textresults)
      end
    end

    before do
      subject.logger = logger

      # システム設定(stub)
      initialize_system_configuration

      # テスト用レコードの初期化
      prepare_manifestation
    end

    after do
      @textfile.destroy if @textfile
    end

    # row_dataに応じたシートにより
    # targetsで指定したレコード(@manifestation、@item、
    # @series_statement、@root_manifestationのいずれか)が
    # 更新されないことを検査する。
    #
    # 更新の有無はvalue_blockからの返り値により判定する。
    #
    # options:
    #   :check_attributes:
    #     value_blockによる検査に加え、各レコードの属性値の検査を行うかどうか
    #     * true - 検査を行う
    #     * :strict - 厳密な検査を行う
    #     * false - 検査を行わない
    #   :ignore_attributes: 属性値検査の際に無視する属性名
    def expect_to_not_change_record!(targets, row_data, options = {}, &value_block)
      block = proc do |target, opts|
        check_attributes = opts.include?(:check_attributes) ? opts[:check_attributes] : true
        if check_attributes == :strict
          ignore_attributes = []

        elsif check_attributes
          if opts.include?(:ignore_attributes)
            ignore_attributes = opts[:ignore_attributes]
          else
            ignore_attributes = %w(lock_version updated_at)
            if target == 'manifestation' || target == 'root_manifestation'
              ignore_attributes << 'date_of_publication'
            end
          end
        end

        record = instance_variable_get(:"@#{target}")
        if record
          record.reload
        else
          value_block = check_attributes = nil
        end

        value = attributes = nil
        if value_block
          value = value_block.call(record)
        end
        if check_attributes
          attributes = record.attributes
          ignore_attributes.each do |name|
            attributes.delete(name)
          end
        end

        [value, attributes]
      end

      values = {}
      targets.each do |target|
        values[target] = block.call(target, options)
      end

      @textfile = create_one_line_textfile(row_data)
      subject.import(@textfile)

      targets.each do |target|
        old_value, old_attributes = values[target]
        new_value, new_attributes = block.call(target, options)
        expect(new_attributes).to eq(old_attributes), "@#{target} changed unexpectedly"
        expect(new_value).to eq(old_value), "@#{target} changed unexpectedly"
      end
    end

    def expect_to_not_change_manifestation!(row_data, opts = {}, &value_block)
      expect_to_not_change_record!(
        %w(manifestation), row_data, opts, &value_block)
      expect(@manifestation.series_statement).to eq(@series_statement),
        '@manifestation.series_statement changed unexpectedly'
    end

    def expect_to_not_change_series_statement!(row_data, opts = {}, &value_block)
      expect_to_not_change_record!(
        %w(series_statement), row_data, opts, &value_block)
    end

    def expect_to_not_change_item!(row_data, opts = {}, &value_block)
      expect_to_not_change_record!(
        %w(item), row_data, opts, &block)
    end

    def expect_to_not_change_root_manifestation!(row_data, opts = {}, &value_block)
      expect_to_not_change_record!(
        %w(root_manifestation), row_data, opts, &value_block)
    end

    def expect_to_not_change_all_records!(row_data, opts = {}, &value_block)
      expect_to_not_change_record!(
        %w(manifestation item series_statement root_manifestation),
        row_data, opts, &value_block)
    end

    # row_dataに応じたシートにより
    # targetsで指定したレコード(@manifestation、@item、
    # @series_statement、@root_manifestationのいずれか)が
    # 更新されることを検査する。
    # 更新の有無はvalue_blockからの返り値により判定する。
    #
    # 一緒に更新されるレコードがある場合には
    # change_ivarsに指定する。
    def expect_to_change_record!(target, row_data, *change_ivars, &value_block)
      others = %w(manifestation item series_statement root_manifestation) - [target] - change_ivars
      record = instance_variable_get(:"@#{target}")
      old_value = value_block.call(record)

      expect_to_not_change_record!(others, row_data)

      record.reload
      new_value = value_block.call(record)
      expect(new_value).to_not eq(old_value), "expected to change @#{target}, but not"
    end

    def expect_to_change_manifestation!(row_data, *change_ivars, &block)
      expect_to_change_record!('manifestation', row_data, *change_ivars, &block)
    end
    def expect_to_change_series_statement!(row_data, *change_ivars, &block)
      expect_to_change_record!('series_statement', row_data, *change_ivars, &block)
    end
    def expect_to_change_item!(row_data, *change_ivars, &block)
      expect_to_change_record!('item', row_data, *change_ivars, &block)
    end
    def expect_to_change_root_manifestation!(row_data, *change_ivars, &block)
      expect_to_change_record!('root_manifestation', row_data, *change_ivars, &block)
    end

    # row_dataによりmodel_classで指定された
    # クラスのレコードが新規作成されることを検査する。
    # model_classはモデルクラスの配列または
    # モデルクラスをキーとし作成数を値とするハッシュで指定する。
    def expect_to_create_record(row_data, model_class, sheet_params = {}, &block)
      external_resource = sheet_params.delete(:external_resource)
      external_resource ||= 'ndl'
      @textfile = create_one_line_textfile(row_data, sheet_params, external_resource)
      exp_block = proc do
        subject.import(@textfile)
      end

      save_ids = {}
      model_class.each do |cls, n|
        save_ids[cls] = cls.pluck(:id)

        n ||= 1
        b = exp_block
        exp_block = proc do
          expect {
            b.call
          }.to change(cls, :count).by(n), "expected to create new #{cls.name} record, but not"
        end
      end

      exp_block.call

      model_class.each do |cls, n|
        (cls.pluck(:id) - save_ids[cls]).each do |new_record_id|
          block.call(cls.find(new_record_id))
        end
      end if block
    end

    def expect_to_create_manifestation(row_data, sheet_params = {}, &block)
      expect_to_create_record(row_data, [Manifestation], sheet_params, &block)
    end
    def expect_to_create_item(row_data, sheet_params = {}, &block)
      expect_to_create_record(row_data, [Item], sheet_params, &block)
    end
    def expect_to_create_series_statement(row_data, sheet_params = {}, &block)
      expect_to_create_record(row_data, [SeriesStatement], sheet_params, &block)
    end

    # row_dataによって与えられた行データにより
    # 指定されたメッセージを発するエラーが起きることを検査する
    def expect_to_return_error_by(row_data, key, sheet_params = {})
      expect_to_not_change_all_records!(row_data)

      results = @textfile.resource_import_textresults
      expect_to_include_message(results, key)
      expect_to_be_success_result(results) # 処理全体としてはエラーにならない
    end

    describe '空ファイルに対し' do
      before do
        @textfile = create_textfile({
          'book' => [[], {}],
        }, 'ndl')
      end

      it 'エラーを返すこと' do
        subject.import(@textfile)
        results = @textfile.resource_import_textresults
        expect_to_be_error_result(results)
        expect_to_include_message(results, 'error.blank_sheet')
      end
    end

    describe '書誌情報だけの行' do
      let(:row_data) do
        {
          'book.manifestation_type' => japanese_book.name,
          'book.original_title' => 'dummy',
        }
      end

      describe '書誌情報IDが記述されている' do
        it '既存の値のとき書誌を更新対象とすること' do
          row_data.merge!({
            "book.identifier" => @manifestation.identifier,
            "book.pub_date" => '2015',
          })
          expect_to_change_manifestation!(row_data, &:pub_date)
          expect_to_be_success_result(@textfile.resource_import_textresults)
        end

        it '未知の値のとき書誌を新規作成すること' do
          row_data.merge!({
            'book.identifier' => 'new_manifestation',
          })
          expect_to_create_manifestation(row_data)
          expect_to_be_success_result(@textfile.resource_import_textresults)
        end
      end

      describe 'ISBNが記述されている' do
        it '既存の値のとき書誌を更新対象とすること' do
          row_data.merge!({
            'book.isbn' => @manifestation.isbn,
            'book.note' => 'new note',
          })
          expect_to_change_manifestation!(row_data, &:note)
          expect_to_be_success_result(@textfile.resource_import_textresults)
        end

        it '未知の値のとき書誌を新規作成すること' do
          Manifestation.should_receive(:import_isbn) do
            FactoryGirl.create(
              :manifestation,
              isbn: isbn2,
              original_title: 'imported',
              manifestation_type: japanese_book)
          end

          row_data.merge!({
            'book.isbn' => isbn2,
          })
          expect_to_create_manifestation(row_data)
          expect_to_be_success_result(@textfile.resource_import_textresults)
        end
      end

      describe '書誌情報ID、ISBNの記述がない' do
        before do
          @agent1 = FactoryGirl.create(:agent)
          @agent2 = FactoryGirl.create(:agent)
          @agent3 = FactoryGirl.create(:agent)
          @manifestation.creators = [@agent1, @agent2]
          @manifestation.publishers = [@agent3]

          row_data.merge!({
            'book.original_title' => @manifestation.original_title,
            'book.pub_date' => @manifestation.pub_date,
          })
        end

        describe 'その他の書誌特定要件記述が満たされている' do
          shared_examples_for 'タイトル、発行日、著者、出版者による書誌の特定' do
            it '既存の値で1レコードのみのとき書誌を更新対象とすること' do
              row_data.merge!({
                'book.note' => 'updated'
              })
              expect_to_change_manifestation!(row_data, &:note)
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end

            it '既存の値で複数あるとき書誌を新規作成すること' do
              manifestation = FactoryGirl.create(
                :manifestation,
                original_title: @manifestation.original_title,
                pub_date: @manifestation.pub_date,
                manifestation_type: japanese_book
              )
              manifestation.save!
              manifestation.creators = @manifestation.creators
              manifestation.publishers = @manifestation.publishers

              expect_to_create_manifestation(row_data)
              expect_to_include_message(@textfile.resource_import_textresults, 'error.book.exist_multiple_same_manifestations')
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end

            it '未知の値のとき書誌を新規作成すること' do
              row_data.merge!({
                "book.original_title" => 'new title',
              })
              expect_to_create_manifestation(row_data)
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end
          end

          context '分割出力指定ONのとき' do
            before do
              add_system_configuration('import_manifestation.use_delim' => false)
              row_data.merge!({
                'book.creator' => @manifestation.creators.pluck(:full_name),
                'book.publisher' => @manifestation.publishers.pluck(:full_name),
              })
            end
            include_examples 'タイトル、発行日、著者、出版者による書誌の特定'
          end

          context '分割出力指定OFFのとき' do
            before do
              add_system_configuration('import_manifestation.use_delim' => true)
              row_data.merge!({
                'book.creator' => @manifestation.creators.pluck(:full_name).join(';'),
                'book.publisher' => @manifestation.publishers.pluck(:full_name).join(';'),
              })
            end
            include_examples 'タイトル、発行日、著者、出版者による書誌の特定'
          end
        end

        describe 'その他の書誌特定要件記述が満たされていない' do
          it '書誌を新規作成すること' do
            expect_to_create_manifestation(row_data)
            expect_to_be_success_result(@textfile.resource_import_textresults)
          end
        end
      end
    end

    describe '書誌情報と所蔵情報からなる行' do
      # ここでは、書誌情報は状況に合わせた最小限とし
      # 主に所蔵情報に基く動作を検査する

      before do
        prepare_items
      end

      let(:row_data) do
        {}
      end

      shared_examples_for '未知の所蔵情報IDが記述されたときの動作' do
        describe '未知の値のとき' do
          before do
            row_data.merge!({
              'book.item_identifier' => 'itemX',
            })
          end

          it 'システム設定import_manifestation.force_create_itemがtrueなら、所蔵を新規作成すること' do
            add_system_configuration('import_manifestation.force_create_item' => true)
            expect_to_create_item(row_data)
          end

          it 'システム設定import_manifestation.force_create_itemがfalseなら、エラーを返すこと' do
            add_system_configuration('import_manifestation.force_create_item' => false)
            expect_to_return_error_by(row_data, 'error.unknown_item_identifier')
          end
        end
      end

      describe '書誌を特定できる' do
        before do
          row_data.merge!({
            'book.identifier' => @manifestation.identifier,
          })
        end

        describe '所蔵情報IDが記述されている' do
          describe '既存の値のとき' do
            before do
              row_data.merge!({
                'book.item_identifier' => @item.item_identifier,
                'book.item_note' => 'updated',
              })
            end

            describe '書誌と所蔵の関係が登録済みデータと一致する' do
              it '所蔵を更新対象とすること' do
                expect_to_change_item!(row_data, &:note)
                expect_to_be_success_result(@textfile.resource_import_textresults)
              end
            end

            describe '書誌と所蔵の関係が登録済みデータと一致しない' do
              before do
                @manifestation_x = FactoryGirl.create(
                  :manifestation,
                  original_title: 'new manifestation',
                  manifestation_type: japanese_book)
                @manifestation_x.reload

                @manifestation.items.delete(@item)
                @manifestation_x.items << @item
              end

              it 'システム設定import_manifestation.exchange_manifestationがtrueなら、シート上の書誌と所蔵を関連付けること' do
                skip 'not implemented yet'
              end

              it 'システム設定import_manifestation.exchange_manifestationがfalseなら、エラーを返すこと' do
                add_system_configuration('import_manifestation.exchange_manifestation' => false)
                expect_to_return_error_by(row_data, 'error.unexpected_item')
              end
            end
          end

          include_examples '未知の所蔵情報IDが記述されたときの動作'
        end

        describe '所蔵情報IDが記述されていない' do
          before do
            # シートにbook.item_identifierの記述がない場合、
            # book.manifestation_typeの記述が必須となるため以下を加えておく
            row_data.merge!({
              'book.manifestation_type' => japanese_book.name,
            })
          end

          it '自動採番の指定があるとき、所蔵を新規作成すること' do
            save_items = @manifestation.items.to_a

            expect_to_create_item(row_data, 'auto_numbering' => true, 'numbering' => 'book')

            item = (@manifestation.items(true) - save_items).first
            expect(item).to be_present
            expect(item.item_identifier).to be_present
          end

          it '自動採番の指定がないとき、エラーを返すこと' do
            expect_to_return_error_by(row_data, 'message.without_item', 'auto_numbering' => false)
          end
        end
      end

      describe '書誌を特定できない' do
        before do
          row_data.merge!({
            'book.original_title' => 'new title',
            'book.manifestation_type' => japanese_book.name,
          })
        end

        describe '所蔵情報IDが記述されている' do
          describe '既存の値のとき' do
            before do
              row_data.merge!({
                'book.item_identifier' => @item.item_identifier,
                'book.item_note' => 'updated',
              })
            end

            it '所蔵を更新対象とすること' do
              expect_to_change_item!(row_data, 'manifestation', &:note)
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end

            it '所蔵から導出された書誌を更新対象とすること' do
              expect_to_change_manifestation!(row_data, 'item', &:original_title)
            end
          end

          include_examples '未知の所蔵情報IDが記述されたときの動作'
        end

        describe '所蔵情報IDが記述されていない' do
          before do
            row_data.merge!({
              'book.item_note' => 'new item',
            })
          end

          it '自動採番の指定があるとき、書誌と所蔵を新規作成すること' do
            new_manifestation = new_item = nil

            expect_to_create_record(
              row_data, [Manifestation, Item],
              'auto_numbering' => true, 'numbering' => 'book'
            ) do |record|
              if record.is_a?(Manifestation)
                new_manifestation = record
              else
                new_item = record
              end
            end

            expect(new_item.item_identifier).to be_present
            expect(new_item.note).to eq('new item')
            expect(new_item.manifestation).to eq(new_manifestation)
            expect(new_manifestation.original_title).to eq('new title')
          end

          it '自動採番の指定がないとき、エラーを返すこと' do
            expect_to_return_error_by(row_data, 'message.without_item', 'auto_numbering' => false)
          end
        end
      end
    end

    describe '書誌情報とシリーズ情報からなる行' do
      # ここでは、書誌情報は状況に合わせた最小限とし
      # 主にシリーズ情報に基く動作を検査する

      before do
        prepare_series_statement
      end

      let(:row_data) do
        {
          'book.manifestation_type' => @manifestation.manifestation_type.name,
        }
      end

      describe '書誌を特定できる' do
        before do
          row_data.merge!({
            'book.identifier' => @manifestation.identifier,
          })
        end

        shared_examples_for 'シリーズと書誌の両方が特定できたときの動作' do
          describe 'シリーズと書誌の関係が登録済みデータと一致する' do
            it 'シリーズを更新対象とすること' do
              expect_to_change_series_statement!(row_data, &:note)
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end
          end

          describe 'シリーズと書誌の関係が登録済みデータと一致しない' do
            before do
              @manifestation_x = FactoryGirl.create(
                :manifestation,
                original_title: 'manifestation X',
                manifestation_type: japanese_magazine)
              @manifestation_x.reload

              @series_statement_x = FactoryGirl.create(
                :series_statement,
                original_title: 'series_statement X',
                periodical: false)

              @manifestation.series_statement = @series_statement_x
              @manifestation_x.series_statement = @series_statement
            end

            describe 'システム設定import_manifestation.exchange_series_statementがtrueのとき' do
              before do
                add_system_configuration(
                  'import_manifestation.exchange_series_statement' => true)
              end

              it 'シリーズを更新対象とすること' do
                skip 'not implemented yet'
                expect_to_change_series_statement!(row_data, &:note)
                expect_to_be_success_result(@textfile.resource_import_textresults)
              end

              it 'シートで指定されたシリーズと書誌を関連付けること' do
                skip 'not implemented yet'
                import_one_line_textfile(row_data)

                @manifestation.reload
                expect(@manifestation.series_statement).to eq(@series_statement)
              end
            end

            describe 'システム設定import_manifestation.exchange_series_statementがfalseのとき' do
              before do
                add_system_configuration(
                  'import_manifestation.exchange_series_statement' => false)
              end

              it 'エラーを返すこと' do
                import_one_line_textfile(row_data) do |results|
                  expect_to_include_message(results, 'error.unexpected_series_statement')
                end
                expect(@manifestation.series_statement).to eq(@series_statement_x)
                expect(@manifestation_x.series_statement).to eq(@series_statement)
              end
            end
          end

          describe 'シリーズと書誌が関連付けされていない' do
            before do
              @manifestation.series_statement = nil
            end

            it 'シリーズを更新対象とすること' do
              expect_to_change_series_statement!(row_data, &:note)
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end

            it 'シリーズと書誌を関連付けること' do
              import_one_line_textfile(row_data)
              @manifestation.reload
              expect(@manifestation.series_statement).to eq(@series_statement)
            end
          end
        end

        shared_examples_for 'シリーズを特定できず書誌を特定できたときの動作' do
          describe '登録済み書誌にシリーズが関連付けられていない' do
            before do
              @manifestation.series_statement = nil
            end

            it '書誌が雑誌等ならシリーズを新規作成すること' do
              expect_to_create_series_statement(row_data) do |new_series_statement|
                @manifestation.reload
                expect(@manifestation.series_statement).to eq(new_series_statement)
              end
              expect_to_be_success_result(@textfile.resource_import_textresults)
            end

            it '書誌が雑誌でないならシリーズをエラーを返すこと' do
              @manifestation.manifestation_type = japanese_book
              @manifestation.save!

              row_data['book.manifestation_type'] = japanese_book.name

              expect {
                expect {
                  import_one_line_textfile(row_data) do |results|
                    expect_to_include_message(results, 'error.unsuitable_manifestation_type')
                  end
                }.to_not change(SeriesStatement, :count)

                @manifestation.reload
              }.to_not change(@manifestation, :series_statement)
            end
          end

          describe '登録済み書誌にシリーズが関連付けられている' do
            skip
          end
        end

        describe 'シリーズ情報IDが記述されている' do
          describe '既存の値のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => @series_statement.series_statement_identifier,
                'series.note' => 'updated',
              })
            end
            include_examples 'シリーズと書誌の両方が特定できたときの動作'
          end

          describe '未知の値のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => 'series_statementX',
                'series.original_title' => 'new series_statement',
                'series.note' => 'new record',
              })
            end
            include_examples 'シリーズを特定できず書誌を特定できたときの動作'
          end
        end

        describe 'シリーズ情報IDの記述がなく、ISSNが記述されている' do
          describe '既存の値のとき' do
            before do
              row_data.merge!({
                'series.issn' => @series_statement.issn,
                'series.note' => 'updated',
              })
            end
            include_examples 'シリーズと書誌の両方が特定できたときの動作'
          end

          describe '未知の値のとき' do
            before do
              row_data.merge!({
                'series.issn' => issn2,
                'series.original_title' => 'new series_statement',
                'series.note' => 'new record',
              })
            end
            include_examples 'シリーズを特定できず書誌を特定できたときの動作'
          end
        end

        describe 'シリーズ情報ID、ISSNの記述がなくシリーズを特定できない' do
          before do
            row_data.merge!({
              'series.original_title' => 'new series_statement',
              'series.note' => 'new record',
            })
          end
          include_examples 'シリーズを特定できず書誌を特定できたときの動作'
        end

        describe 'シリーズ情報IDとISSNが記述されている' do
          describe 'シリーズ情報IDが既存値、ISSNが未知のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => @series_statement.series_statement_identifier,
                'series.issn' => issn2,
              })
            end

            it 'シリーズのISSNを更新すること' do
              expect_to_change_series_statement!(row_data, &:issn)
              expect(@series_statement.issn).to eq(issn2)
            end
          end

          describe 'シリーズ情報IDが未知、ISSNが既存値のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => 'unknwon',
                'series.issn' => @series_statement.issn,
                'series.original_title' => @series_statement.original_title, # 結果的に新規作成されるシリーズのために必要となる
              })
            end

            it '既存シリーズを変更しないこと' do
              expect_to_not_change_series_statement!(row_data)
            end

            it 'シリーズを新規作成すること' do
              expect_to_create_series_statement(row_data) do |new_series_statement|
                expect(new_series_statement.series_statement_identifier).to eq('unknwon')
                @manifestation.reload
                expect(@manifestation.series_statement).to eq(new_series_statement)
              end
            end
          end

          describe '両値がそれぞれ別のシリーズを指すとき' do
            before do
              @series_statement2 = FactoryGirl.create(
                :series_statement,
                original_title: 'test series_statement 2',
                series_statement_identifier: 'series_statement2',
                issn: issn2,
                periodical: false)
            end

            describe '特定された書誌に関連付けられたシリーズが見付かったとき' do
              before do
                # シリーズ情報IDはseries_statement2を、ISSNは@series_statementを指す
                row_data.merge!({
                  'series.series_statement_identifier' => @series_statement2.series_statement_identifier,
                  'series.issn' => @series_statement.issn,
                })
              end

              skip
            end

            describe '特定された書誌に関連しないシリーズが見付かったとき' do
              before do
                @series_statement3 = FactoryGirl.create(
                  :series_statement,
                  original_title: 'test series_statement 3',
                  series_statement_identifier: 'series_statement3',
                  issn: issn3,
                  periodical: false)

                row_data.merge!({
                  'series.series_statement_identifier' => @series_statement2.series_statement_identifier,
                  'series.issn' => @series_statement3.issn,
                })
              end

              skip
            end
          end
        end

        describe '書誌種別を厳密に扱う' do
          before do
            ResourceImport.stub(:strict_series_statement_binding? => true)

            @manifestation.series_statement = nil
            @manifestation.manifestation_type = japanese_book
            @manifestation.save!
          end

          it '書誌がシリーズでないなら、シート上のシリーズ情報を適用しないこと' do
            row_data.merge!('series.note' => 'new note')
            expect_to_not_change_record!(
              %w(manifestation series_statement), row_data)
          end
        end
      end

      describe '書誌を特定できない' do
        # シート上の記述でシリーズ(@series_statement)の特定はできるが
        # 書誌(@manifestation)の特定はできないケース。
        # ただし、DB上では@manifestation.series_statement==@series_statementである。

        before do
          row_data.merge!({
            'book.original_title' => @manifestation.original_title,
          })
        end

        shared_examples_for 'シリーズを特定でき、書誌を特定できなかったときの動作' do
          it 'シリーズを更新対象とすること' do
            expect_to_change_series_statement!(row_data, &:note)
            expect_to_be_success_result(@textfile.resource_import_textresults)
          end

          it '書誌を変更しないこと' do
            expect_to_not_change_manifestation!(row_data)
          end

          it '書誌を新規作成すること' do
            expect_to_create_manifestation(row_data) do |new_manifestation|
              expect(new_manifestation.series_statement).to eq(@series_statement)
            end
          end
        end

        shared_examples_for 'シリーズと書誌の両方を特定できなかったときの動作' do
          it '書誌、シリーズを新規作成すること' do
            new_manifestation = new_series_statement = nil
            expect_to_create_record(row_data, Manifestation => 1, SeriesStatement => 1) do |new_record|
              if new_record.is_a?(Manifestation)
                new_manifestation = new_record
              else
                new_series_statement = new_record
              end
            end

            expect(new_manifestation.series_statement).to eq(new_series_statement)
          end
        end

        describe 'シリーズ情報IDが記述されている' do
          describe '既存の値のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => @series_statement.series_statement_identifier,
                'series.note' => 'updated',
              })
            end
            include_examples 'シリーズを特定でき、書誌を特定できなかったときの動作'
          end

          describe '未知の値のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => 'series_statementX',
                'series.original_title' => 'new series_statement',
                'series.note' => 'new record',
              })
            end
            include_examples 'シリーズと書誌の両方を特定できなかったときの動作'
          end
        end

        describe 'シリーズ情報IDの記述がなく、ISSNが記述されている' do
          describe '既存の値のとき' do
            before do
              row_data.merge!({
                'series.issn' => @series_statement.issn,
                'series.note' => 'updated',
              })
            end
            include_examples 'シリーズを特定でき、書誌を特定できなかったときの動作'
          end

          describe '未知の値のとき' do
            before do
              row_data.merge!({
                'series.issn' => issn2,
                'series.original_title' => 'new series_statement',
                'series.note' => 'new record',
              })
            end
            include_examples 'シリーズと書誌の両方を特定できなかったときの動作'
          end
        end

        describe 'シリーズ情報ID、ISSNの記述がなくシリーズを特定できない' do
          before do
            row_data.merge!({
              'series.original_title' => 'new series_statement',
              'series.note' => 'new record',
            })
          end
          include_examples 'シリーズと書誌の両方を特定できなかったときの動作'
        end

        describe 'シリーズ情報IDとISSNが記述されている' do
          describe 'シリーズ情報IDが既存値、ISSNが未知のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => @series_statement.series_statement_identifier,
                'series.issn' => issn2,
              })
            end

            it 'シリーズのISSNを更新すること' do
              expect_to_change_series_statement!(row_data, &:issn)
              expect(@series_statement.issn).to eq(issn2)
            end
          end

          describe 'シリーズ情報IDが未知、ISSNが既存値のとき' do
            before do
              row_data.merge!({
                'series.series_statement_identifier' => 'unknwon',
                'series.issn' => @series_statement.issn,
                'series.original_title' => @series_statement.original_title, # 結果的に新規作成されるシリーズのために必要となる
              })
            end

            it '既存シリーズを変更しないこと' do
              expect_to_not_change_series_statement!(row_data)

              @manifestation.reload
              expect(@manifestation.series_statement).to eq(@series_statement)
            end

            it 'シリーズを新規作成すること' do
              expect_to_create_series_statement(row_data) do |new_series_statement|
                expect(new_series_statement.series_statement_identifier).to eq('unknwon')
              end
            end
          end

          describe '両値がそれぞれ別のシリーズを指すとき' do
            before do
              @series_statement2 = FactoryGirl.create(
                :series_statement,
                original_title: 'test series_statement 2',
                series_statement_identifier: 'series_statement2',
                issn: issn2,
                periodical: false)

              @series_statement3 = FactoryGirl.create(
                :series_statement,
                original_title: 'test series_statement 3',
                series_statement_identifier: 'series_statement3',
                issn: issn3,
                periodical: false)

              row_data.merge!({
                'series.series_statement_identifier' => @series_statement2.series_statement_identifier,
                'series.issn' => @series_statement3.issn,
              })
            end

            skip
          end
        end
      end
    end

    describe '書誌情報とroot書誌情報からなる行' do
      # ここでは、書誌情報は状況に合わせた最小限とし
      # 主にroot書誌情報に基く動作を検査する

      before do
        prepare_series_statement
        prepare_root_manifestation
      end

      let(:row_data) do
        {
          'book.manifestation_type' => @manifestation.manifestation_type.name,
          'series.original_title' => @series_statement.original_title, # シリーズ特定には致らないが、シート要件チェックをパスできる指定
        }
      end

      describe '書誌を特定できる' do
        before do
          row_data.merge!({
            'book.identifier' => @manifestation.identifier,
            'root.description' => 'updated',
          })
        end

        it 'root書誌を更新対象とすること' do
          expect_to_change_root_manifestation!(row_data, &:description)
        end
      end

      describe '書誌を特定できない' do
        before do
          row_data.merge!({
            'book.original_title' => @manifestation.original_title,
            'root.description' => 'dummy',
          })
        end

        it '既存レコードを変更しないこと' do
          expect_to_not_change_all_records!(row_data)
        end

        it '書誌、シリーズ、root書誌を新規作成すること' do
          expect_to_create_record(
            row_data,
            Manifestation => 1,
            SeriesStatement => 1)
        end
      end
    end

    describe 'シリーズ情報とroot書誌情報からなる行' do
      # ここでは、シリーズ情報は状況に合わせた最小限とし
      # 主にroot書誌情報に基く動作を検査する

      before do
        prepare_series_statement
        prepare_root_manifestation
      end

      let(:row_data) do
        {
          'book.manifestation_type' => @manifestation.manifestation_type.name,
          'book.original_title' => @manifestation.original_title, # 書誌の特定には致らないが、シート要件チェックをパスできる指定
        }
      end

      describe 'シリーズを特定できる' do
        before do
          row_data.merge!({
            'series.series_statement_identifier' => @series_statement.series_statement_identifier,
            'root.description' => 'updated',
          })
        end

        it 'root書誌を更新対象とすること' do
          expect_to_change_root_manifestation!(row_data, &:description)
        end
      end

      describe 'シリーズを特定できない' do
        before do
          row_data.merge!({
            'series.original_title' => @series_statement.original_title,
            'root.description' => 'dummy',
          })
        end

        it '既存レコードを変更しないこと' do
          expect_to_not_change_all_records!(row_data)
        end

        it '書誌、シリーズ、root書誌を新規作成すること' do
          expect_to_create_record(
            row_data,
            Manifestation => 1,
            SeriesStatement => 1)
        end
      end
    end

    describe '分類記号が' do
      let(:row_data) do
        [
          ['book.identifier', @manifestation.identifier],
          ['book.manifestation_type', @manifestation.manifestation_type.name],
        ]
      end

      before do
        @type_ndc9 = FactoryGirl.create(:classification_type, name: 'ndc9')
        @classification0 = FactoryGirl.create(
          :classification,
          classification_type_id: @type_ndc9.id,
          classifiation_identifier: 'classification0')
        @classification1 = FactoryGirl.create(
          :classification,
          classification_type_id: @type_ndc9.id,
          classifiation_identifier: 'classification1')
        @classification2 = FactoryGirl.create(
          :classification,
          classification_type_id: @type_ndc9.id,
          classifiation_identifier: 'classification2')

        @type_foo = FactoryGirl.create(:classification_type, name: 'foo')
        @classification3 = FactoryGirl.create(
          :classification,
          classification_type_id: @type_foo.id,
          classifiation_identifier: 'classification3')

        @manifestation.classifications << @classification0
      end

      describe '記述されている' do
        describe '分割指定ONのとき' do
          before do
            add_system_configuration('import_manifestation.use_delim' => false)
          end

          it '書誌の分類記号を更新すること' do
            row_data << [
              ['book.classification', @classification1.category],
              ['book.classification_type', @classification1.classification_type.name]
            ]
            row_data << [
              ['book.classification', @classification3.category],
              ['book.classification_type', @classification3.classification_type.name]
            ]

            import_one_line_textfile(row_data)
            @manifestation.reload
            expect(@manifestation.classifications).to include(@classification1)
            expect(@manifestation.classifications).to include(@classification3)

            row_data << [
              ['book.classification', @classification0.category],
              ['book.classification_type', @classification0.classification_type.name]
            ]

            import_one_line_textfile(row_data)
            @manifestation.reload
            expect(@manifestation.classifications).to include(@classification0)
            expect(@manifestation.classifications).to include(@classification1)
            expect(@manifestation.classifications).to include(@classification3)
          end

          it '空の分類記号が指定されたとき、書誌の分類記号を空にすること' do
            row_data << [
              ['book.classification', nil],
              ['book.classification_type', nil]
            ]

            import_one_line_textfile(row_data)
            @manifestation.reload
            expect(@manifestation.classifications).to be_blank
          end

          it '存在しない分類記号が指定されたとき、エラーを返すこと' do
            row_data << [
              ['book.classification', @classification1.category],
              ['book.classification_type', @type_foo.name]
            ]

            import_one_line_textfile(row_data) do |results|
              expect_to_include_message(results, 'error.unknown_classification',
                                        type: @type_foo.name, category: @classification1.category)
            end
          end
        end

        describe '分割指定OFFのとき' do
          before do
            add_system_configuration('import_manifestation.use_delim' => true)
          end

          it '書誌の分類記号を更新すること' do
            rd = row_data.dup
            rd << ['book.classification',
              [@classification1.category, @classification2.category].join(';')]
            import_one_line_textfile(rd)

            @manifestation.reload
            expect(@manifestation.classifications).to include(@classification1)
            expect(@manifestation.classifications).to include(@classification2)

            rd = row_data.dup
            rd << ['book.classification',
              [@classification0.category, @classification1.category, @classification2.category].join(';')]
            import_one_line_textfile(rd)

            @manifestation.reload
            expect(@manifestation.classifications).to include(@classification0)
            expect(@manifestation.classifications).to include(@classification1)
            expect(@manifestation.classifications).to include(@classification2)
          end

          it '空の分類記号が指定されたとき、書誌の分類記号を空にすること' do
            row_data << ['book.classification', nil]

            import_one_line_textfile(row_data)
            @manifestation.reload
            expect(@manifestation.classifications).to be_blank
          end

          it 'ndc9に存在しない分類記号が指定されたとき、エラーを返すこと' do
            row_data << ['book.classification', @classification3.category]

            import_one_line_textfile(row_data) do |results|
              expect_to_include_message(results, 'error.unknown_classification',
                                        type: 'ndc9', category: @classification3.category)
            end
          end
        end
      end

      describe '記述されていない' do
        it '分類記号を変更しないこと' do
          expect {
            import_one_line_textfile(row_data)
            @manifestation.reload
          }.to_not change(@manifestation, :classifications)
        end
      end
    end
  end

  context 'エクセルファイルのインポート' do
    # data: 以下の形式のハッシュ(*1の部分はsheet_rowsに渡せる形式)
    #   {'book' => [...(*1)], ...}
    # external_resource: nil、'ndl'または'nacsis'
    def create_textfile(data, external_resource)
      Tempfile.open(['resource_import_test', '.xlsx']) do |tf|
        file_params = []
        Axlsx::Package.new do |pkg|
          wb = pkg.workbook
          data.each_with_index do |(sheet_name, (rows, sheet_params)), i|
            wb.add_worksheet(name: sheet_name) do |ws|
              sheet_rows(rows).each do |row|
                Rails.logger.debug "row: #{row.inspect}"
                ws.add_row(row, types: :string)
              end
            end
            file_params[i] ||= {}
            file_params[i]['sheet'] = sheet_name
            sheet_params.each do |key, value|
              file_params[i][key] = value
            end
          end
          pkg.serialize(tf.path)
        end
        create_resource_import_textfile(
          tf, 'Excelfile_Adapter', file_params, external_resource)
      end
    end
    include_examples 'インポート機能'
  end

  context 'CSVファイルのインポート' do
    def create_textfile(data, external_resource) # エクセル側と同じインタフェースにする
      if SystemConfiguration.get('set_output_format_type')
        ext = '.tsv'
        sep = "\t"
      else
        ext = '.csv'
        sep = ','
      end
      Tempfile.open(['resource_import_test', ext]) do |tf|
        tf.print "\xEF\xBB\xBF"
        file_params = [{}]
        CSV(tf, col_sep: sep, force_quotes: true) do |csv|
          data.each do |sheet_name, (rows, sheet_params)|
            sheet_rows(rows).each do |row|
              Rails.logger.debug "row: #{row.inspect}"
              csv << row
            end
            file_params[0]['sheet'] = sheet_name
            sheet_params.each do |key, value|
              file_params[0][key] = value
            end
          end
        end
        create_resource_import_textfile(
          tf, 'Tsvfile_Adapter', file_params, external_resource)
      end
    end
    include_examples 'インポート機能'
  end
end

