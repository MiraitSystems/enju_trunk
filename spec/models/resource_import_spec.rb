# encoding: utf-8
require 'spec_helper'

describe ResourceImport do
  fixtures :languages, :countries, :carrier_types, :frequencies, :agents, :agent_types, :roles

  def create_resource_import_textfile(file, adapter_name, textfile_params, external_resource)
    # 基本的にはResourceImportTextfilesController#createの動作を模倣する
    extraparams = {
      'sheet' => [],
      'manifestation_types' => [],
      'numberings' => [],
      'auto_numberings' => [],
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
      extraparams: extraparams.to_s)
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
        fk, *vals = kv
        if fk.is_a?(Array)
          kv.each do |fk, val|
            row[fk] ||= []
            row[fk] << val
          end
        else
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
        if n == 1 && spec[fk] == :singular
          header << field_name(fk) if rows.size == 1
          row << rd[fk].first
        elsif n == 1
          header << field_name(fk) if rows.size == 1
          row << rd[fk].join(';')
        else
          1.upto(column[field_key]) do |i|
            header << field_name(fk, i) if rows.size == 1
            row << rd[fk][i]
          end
        end
      end
    end
  end

  def create_one_line_textfile(sheet_name, row, sheet_params = {}, external_resource = 'ndl')
    create_textfile({sheet_name => [[row], sheet_params]}, external_resource)
  end

  shared_examples_for 'インポート機能' do
    describe '#importは' do
      before do
        add_system_configuration({
          'manifestations.split_by_type' => false,
          'set_output_format_type' => true, # true:tsv, false:csv
          'add_only_exist_agent' => true,
          'manifestation.isbn_unique' => true,
        })
        Manifestation.reinitialize_output_column_spec # システム設定manifestations.split_by_typeにより定義が変わるため再初期化が必要

        @logger = []
        def @logger.method_missing(sym, *args)
          Rails.logger.__send__(sym, *args)
          self << [sym, *args]
        end
        subject.logger = @logger
      end

      describe '空ファイルに対し' do
        before do
          @textfile = create_textfile({
            'book' => [[], {}],
          }, 'ndl')
        end

        after do
          @textfile.destroy
        end

        it 'エラーを返すこと' do
          subject.import(@textfile)

          results = @textfile.resource_import_textresults
          expect(results).to be_present
          expect(results.last).to be_failed
          expect(results.last.error_msg).to match(I18n.t('resource_import_textfile.error.blank_sheet'))
        end
      end

      describe '新規書誌を含むファイルにより' do
        before do
          @manifestation_type = FactoryGirl.create(:manifestation_type)
          @attributes = {
            'book.manifestation_type' => @manifestation_type.name,
            'book.original_title' => 'test title',
          }
          @textfile = create_one_line_textfile('book', @attributes)
        end

        after do
          @textfile.destroy
        end

        it '書誌を新規作成すること' do
          expect {
            subject.import(@textfile)
          }.to change(Manifestation, :count).by(1)
        end

        it '書誌の属性値を設定すること' do
          subject.import(@textfile)

          m = Manifestation.last

          expect(m.manifestation_type).to eq(@manifestation_type)
          expect(m.original_title).to eq(@attributes['book.original_title'])
        end
      end

      describe '既存書誌を含むファイルにより' do
        before do
          identifier = 'foobarbaz'
          mt = FactoryGirl.create(:manifestation_type)
          @manifestation = FactoryGirl.create(
            :manifestation,
            original_title: 'test title',
            identifier: identifier,
            manifestation_type_id: mt.id
          )
          @textfile = create_one_line_textfile('book', {
            'book.original_title' => 'updated',
            'book.identifier' => @manifestation.identifier,
            'book.manifestation_type' => @manifestation.manifestation_type.name,
          })
        end

        after do
          @textfile.destroy
        end

        it '書誌を更新すること' do
          subject.import(@textfile)

          @manifestation.reload
          expect(@manifestation.original_title).to eq('updated')
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

