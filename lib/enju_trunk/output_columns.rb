# -*- encoding: utf-8 -*-
require 'csv'

module EnjuTrunk
  module OutputColumns
    extend ActiveSupport::Concern

    OUTPUT_COLUMN_SPEC = {}
    OUTPUT_COLUMN_FIELDS = %w(book article series root)
    OUTPUT_COLUMN_INTERNAL_FIELDS = %w(root)
    OUTPUT_COLUMN_TYPES = [:singular, :plural, :none]

    included do
      cattr_accessor :book_output_columns_cache
      cattr_accessor :article_output_columns_cache
      cattr_accessor :series_output_columns_cache
      cattr_accessor :all_output_columns_cache

      initialize_output_column_spec
    end

    module ClassMethods
      # 出力カラム定義を初期化する。
      #
      #   spec_hash: 定義を設定するハッシュを指定する
      #   force_all: 設定などにより実行時には使用されない定義も含める
      def initialize_output_column_spec(spec_hash = OUTPUT_COLUMN_SPEC, force_all = false)
        clear_cache!

        code, spec = IO.read(__FILE__).gsub(/\r\n/, "\n").split(/^__END__\n/, 2)
        first_line = true
        CSV.parse(spec) do |fields, field_ext, ja, en, for_join, for_separate|
          next if fields.blank?
          if first_line
            first_line = false
            next
          end

          if field_ext == 'manifestation_type' &&
              SystemConfiguration.get('manifestations.split_by_type') &&
              !force_all
            next
          end

          if (field_ext == 'theme' || field_ext == 'theme_publish') &&
              !defined?(EnjuTrunkTheme) &&
              !force_all
            # TODO:
            # theme、theme_publishについては
            # enju_trunk_theme側の設定ファイルで
            # add_output_column_specするようにする
            next
          end

          add_output_column_spec(
            fields.split(/\s+/), field_ext,
            {ja: ja, en: en},
            for_join.to_sym, for_separate.to_sym,
            spec_hash)
        end

        spec_hash
      end

      def reinitialize_output_column_spec(spec_hash = OUTPUT_COLUMN_SPEC, force_all = false)
        spec_hash.clear
        initialize_output_column_spec(spec_hash, force_all)
      end

      # 出力カラムの定義を追加する
      #
      #   fields:
      #     book、article、series、rootのどれかからなる配列
      #   field_ext:
      #     内部キーを構成するための名前
      #   field_names:
      #     内部キーに対応する表示名(項目名)を示すハッシュ
      #   for_join: 分割指定OFFのときの扱い方を指定する
      #     :singular: 単一項目とする
      #     :plural: 複数項目とする
      #     :none: 対象としない
      #   for_separate: 分割指定ONのときの扱い方を指定する
      #     :singular: 単一項目とする
      #     :plural: 複数項目とする
      #     :none: 対象としない
      #
      # 例: config/initializersで追加設定をする:
      # 
      #   Rails.application.config.after_initialize do
      #     Manifestation.add_output_column_spec(
      #       %w(book), 'manifestation_exinfo.test_exinfo1',
      #       {ja: 'テストexinfo1', en: 'Test exinfo1'}, :singular, :singular)
      #     Manifestation.add_output_column_spec(
      #       %w(book), 'manifestation_exinfo.test_exinfo2',
      #       {ja: 'テストexinfo2', en: 'Test exinfo2'}, :singular, :singular)
      #   end
      #
      # 注意:
      # 以上の指定は表示名に関する扱いについて定義するもので
      # 実際のエクスポート・インポートの動作は各機能の実装による。
      def add_output_column_spec(fields, field_ext, field_names, for_join, for_separate, spec_hash = OUTPUT_COLUMN_SPEC)
        fields = [fields].flatten.map(&:to_s)
        unknown = fields - OUTPUT_COLUMN_FIELDS
        unless unknown.empty?
          raise ArgumentError, "unknown field: #{unknown.join(', ')}"
        end

        field_ext = field_ext.to_s
        if /\A[a-z][_.a-z\d]+\z/ !~ field_ext
          raise ArgumentError, "invalid field_ext: #{field_ext}"
        end

        unless field_names.is_a?(Hash)
          raise TypeError, "unexpected type: field_names"
        end

        unless OUTPUT_COLUMN_TYPES.include?(for_join)
          raise ArgumentError, "invalid for_join: #{for_join.inspect}"
        end

        unless OUTPUT_COLUMN_TYPES.include?(for_separate)
          raise ArgumentError, "invalid for_separate: #{for_separate.inspect}"
        end

        fields.each do |field|
          field_key = "#{field}.#{field_ext}"
          if spec_hash.include?(field_key)
            raise "field_key `#{field_key}' already exists"
          end

          spec_hash[field_key] = [
            for_join, for_separate, field_names
          ]
        end

        clear_cache!
        nil
      end

      # 分割指定がONならばtrueを、OFFならばfalseを返す
      def separate_output_columns?
        !SystemConfiguration.get('import_manifestation.use_delim')
      end

      def output_column_defined?(field_key, spec_hash = OUTPUT_COLUMN_SPEC)
        spec_hash.include?(field_key)
      end

      def output_column_spec(spec_hash = OUTPUT_COLUMN_SPEC)
        spec_hash
      end

      def select_output_column_spec(field, spec_hash = OUTPUT_COLUMN_SPEC)
        separation = separate_output_columns?
        if field == :all
          regexp = nil
        else
          regexp = /\A#{Regexp.quote(field)}\./
        end
        spec_hash.inject({}) do |specs, (field_key, (for_join, for_separate, field_names))|
          if regexp.nil? || regexp =~ field_key
            type = separation ? for_separate : for_join
            specs[field_key] = type unless type == :none
          end
          specs
        end
      end

      def book_output_columns
        self.book_output_columns_cache ||=
          select_output_column_spec('book').keys
      end

      def article_output_columns
        self.article_output_columns_cache ||=
          select_output_column_spec('article').keys
      end

      def series_output_columns
        self.series_output_columns_cache ||=
          select_output_column_spec('series').keys
      end

      def all_output_columns
        # NOTE: 内部的に使用するrootは含めない
        self.all_output_columns_cache ||=
          series_output_columns +
            book_output_columns +
            article_output_columns # 出力時の順番に関わるので series と book の順番を入れ替えないこと
      end

      # config/locale用のYAMLテキストを生成し、
      # ロケールをキーとしたハッシュで返す。
      #
      # 例:
      #
      #   translation_for_output_columns.each do |locale, yaml_text|
      #     open("config/locales/resource_import_textfile_excel_#{locale}.yml", 'w') do |io|
      #       io.print yaml_text
      #     end
      #   end
      #
      def translation_for_output_columns
        translation = {}
        column_spec = {}
        initialize_output_column_spec(column_spec, true)

        column_spec.each do |field_key, (for_join, for_separate, field_names)|
          field_names.each do |locale, name|
            translation[locale] ||= {}
            *branch, last_seg = field_key.split(/\./)
            leaf = branch.
              inject(translation[locale]) do |sub, seg|
                unless sub.is_a?(Hash)
                  raise "conflicts Hash and String on `#{field_key}'"
                end
                sub[seg] ||= {}
                sub[seg]
              end
            leaf[last_seg] = name
          end
        end

        translation.keys.each do |locale|
          translation[locale] = {
            locale.to_s => {
              'resource_import_textfile' => {
                'excel' => translation[locale]
              }
            }
          }
        end

        translation.inject({}) do |result, (locale, hash)|
          result[locale] = YAML.dump(hash).sub(/\A---\n/, '')
          result
        end
      end

      private

        def clear_cache!
          self.book_output_columns_cache = nil
          self.article_output_columns_cache = nil
          self.series_output_columns_cache = nil
          self.all_output_columns_cache = nil
        end
    end # module ClassMethods
  end # module OutputColumns
end # module EnjuTrunk

__END__
内部キー(主),内部キー(副),表示名(日),表示名(英),分割OFFのとき,分割ONのとき,主な情報ソース,備考
article,title,誌名,Title of journal,singular,singular,manifestation,
book article,original_title,タイトル,Title,singular,singular,manifestation,
book,title_transcription,タイトル（ヨミ）,Title(transcription),singular,singular,manifestation,
book,title_alternative,代替タイトル,Alternative title,singular,singular,manifestation,
book root,other_title,その他のタイトル,Other title,plural,plural,manifestation,
book root,other_title_type,その他のタイトルタイプ,Other title type,plural,plural,manifestation,
book,identifier,識別子,Identifier,singular,singular,manifestation,
book,other_identifier,その他の識別子,Other identifier,plural,plural,manifestation,
book,other_identifier_type,その他の識別子タイプ,Other identifier type,plural,plural,manifestation,
book root,carrier_type,資料の形態,Carrier type,singular,singular,manifestation,
book root,manifestation_type,資料区分,Manifestation type,singular,singular,manifestation,
book root,jpn_or_foreign,和洋区分,Japan or foreign,singular,singular,manifestation,
book root article,pub_date,出版日,Date of publication,singular,singular,manifestation,
book root,country_of_publication,出版国,Country of publication,singular,singular,manifestation,
book root,place_of_publication,出版地,Place of publication,singular,singular,manifestation,
book root,language,言語,Language,singular,plural,manifestation,
book root,language_type,言語タイプ,Language type,none,plural,manifestation,
book root,edition_display_value,版表示,Edition statement,singular,singular,manifestation,
book root article,volume_number_string,巻,Volume number,singular,singular,manifestation,
book root,issue_number_string,号,Issue number,singular,singular,manifestation,
book root,serial_number,通号（数字）,Serial number(numeric),singular,singular,manifestation,
book root,serial_number_string,通号,Serial number,singular,singular,manifestation,
book,isbn,ISBN,ISBN,singular,singular,manifestation,
book,wrong_isbn,間違ったISBN,Wrong ISBN,singular,singular,manifestation,
book,nbn,NBN,NBN,singular,singular,manifestation,
book,lccn,LCCN,LCCN,singular,singular,manifestation,
book,marc_number,MARC番号,MARC number,singular,singular,manifestation,
book,ndc,NDC,NDC,singular,singular,manifestation,
article,number_of_page,ページ,Pages,singular,singular,manifestation,
book,start_page,最初のページ,Start page,singular,singular,manifestation,
book,end_page,最後のページ,End page,singular,singular,manifestation,
book,height,高さ(cm),Height(cm),singular,singular,manifestation,
book,width,幅(cm),Width(cm),singular,singular,manifestation,
book,depth,奥行き(cm),Depth(cm),singular,singular,manifestation,
book,size,サイズ,Size,singular,singular,manifestation,
book root,price,価格,Price,singular,singular,manifestation,
article,access_address,URL,URL,singular,singular,manifestation,
book root,access_address,アクセスアドレス,Access address,singular,singular,manifestation,
book root,repository_content,リポジトリのコンテンツ,Repository content,singular,singular,manifestation,
book root,required_role,参照に必要な権限,Required role,singular,singular,manifestation,
book root,except_recent,新刊対象から除外,Excep recent,singular,singular,manifestation,
book root,description,説明,Description,singular,singular,manifestation,
book root,supplement,付録,Supplement,singular,singular,manifestation,
book,note,注記,Note,singular,singular,manifestation,
book,missing_issue,欠号管理,Missing issue,singular,singular,manifestation,
book,acceptance_number,受入部数,Accept number,singular,singular,manifestation,
book root,use_license,著者抄録許諾(許諾機関名称),Use license,singular,singular,manifestation,
article,creator,著者,Creator,singular,singular,manifestation,
book root,creator,著者,Creator,singular,plural,manifestation,
book root,creator_transcription,著者(ヨミ),Creator(transcription),none,plural,manifestation,
book root,creator_type,著者タイプ,Creator type,none,plural,manifestation,
book root,contributor,編者,Contributor,singular,plural,manifestation,
book root,contributor_transcription,編者(ヨミ),Contributor(transcription),none,plural,manifestation,
book root,contributor_type,編者タイプ,Contributor type,none,plural,manifestation,
book root,publisher,出版者,Publisher,singular,plural,manifestation,
book root,publisher_transcription,出版者(ヨミ),Publisher(transcription),none,plural,manifestation,
book root,publisher_type,出版者タイプ,Publisher type,none,plural,manifestation,
article,subject,件名,Subject,singular,singular,manifestation,
book root,subject,件名,Subject,singular,plural,manifestation,
book root,subject_transcription,件名(ヨミ),Subject(transcription),singular,plural,manifestation,
book,theme,テーマ,Theme,plural,plural,manifestation,
book,theme_publish,テーマ公開範囲,Theme publish,plural,plural,manifestation,
book,classification,分類記号,Classification,singular,plural,manifestation,
book,classification_type,分類種類,Classification type,none,plural,manifestation,
book,shelf,本棚,Shelf,singular,singular,item,
book,checkout_type,貸出区分,Checkout type,singular,singular,item,
book,accept_type,受入区分,Accept type,singular,singular,item,
book,circulation_status,貸出状態,Circulation status,singular,singular,item,
book,retention_period,保存種別,Retention period,singular,singular,item,
book article,call_number,請求記号,Call number,singular,singular,item,
book,bookstore,寄贈・購入先,Bookstore,singular,singular,item,
book,item_price,購入価格,Purchase price,singular,singular,item,
book,url,URL,URL,singular,singular,item,
book,include_supplements,付録を含む,Include supplements,singular,singular,item,
book,use_restriction,利用制限,Use restriction,singular,singular,item,
book,item_required_role,所蔵の参照に必要な権限,Item required role,singular,singular,item,
book,non_searchable,検索対象から除外,Non searchable,singular,singular,item,
book,acquired_at,受入日,Date of accession,singular,singular,item,
book,item_note,所蔵注記,Item note,singular,singular,item,
book,rank,正本区分,Rank,singular,singular,item,
book,item_identifier,所蔵情報ID,Item identifier,singular,singular,item,
book,nacsis_identifier,NCID,NCID,singular,singular,manifestation,マッピング表にない
book,frequency,発行頻度,Frequency,singular,singular,manifestation,マッピング表にない
book,dis_date,出版停止日,,singular,singular,manifestation,マッピング表にない
book,library,図書館,Library,singular,singular,item,マッピング表にない
book,remove_reason,除籍理由,Removed reason,singular,singular,item,マッピング表にない
book article,del_flg,削除フラグ,Delete flag,singular,singular,*,
series,original_title,シリーズ名,Series name,singular,singular,series_statement,
series,title_transcription,シリーズ名（ヨミ）,Series name(transcription),singular,singular,series_statement,
series,periodical,定期刊行物,Periodical,singular,singular,series_statement,
series,issn,ISSN,ISSN,singular,singular,series_statement,
series,jpno,JPNO,JPNO,singular,singular,series_statement,
series,series_statement_identifier,シリーズ識別子,Series statement identifier,singular,singular,series_statement,
series,sequence_pattern,刊行パターン,Sequence Pattern,singular,singular,series_statement,
series,publication_status,出版状況,Publication status,singular,singular,series_statement,
series,note,雑誌注記,Series note,singular,singular,series_statement,
