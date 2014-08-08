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

        spec_file = Gem::Specification.find_by_name("enju_trunk").gem_dir + '/lib/enju_trunk/columns_spec.csv'
        spec = File.read(spec_file)
        first_line = true
        CSV.parse(spec) do |fields, field_ext, ja, en, for_join, for_separate, resource_model|
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

          # default values 
          ja = I18n.t("activerecord.attributes.#{resource_model}.#{field_ext.split('.').first}", :locale => :ja) if ja.blank?
          en = I18n.t("activerecord.attributes.#{resource_model}.#{field_ext.split('.').first}", :locale => :en) if en.blank?
          for_join = 'singular' if for_join.blank?
          for_separate = 'singular' if for_separate.blank?

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
