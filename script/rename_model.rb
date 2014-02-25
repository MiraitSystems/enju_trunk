# encoding: utf-8
#
# 指定された語を含むモデル名を変更する。
# 以下の処理を行う。
#
#  * ディレクトリ名の変更
#  * ファイル名の変更
#  * ファイル中の記述の変更
#  * DBスキーマの変更(マイグレーションの生成)
#
# スプリプト実行後、以下を実行すること。
#
#  * rake db:migrate
#  * solr reindex
#  * gemspecがある場合にはその内容の更新
#
# 制限事項:
#
#  * 階層化されたモデル(Foo::Bar)の指定には対応しない。
#  * 既存DB内のデータは変更しない。(特に設定系に注意。)
require 'active_support/core_ext/string/inflections'
require 'optparse'
require 'find'

if ARGV.first == '--'
  ARGV.shift
end

def git_cmd(args, options)
  cmd = ['git', *args]
  puts cmd.join(' ') if options[:verbose]
  system(*cmd) unless options[:dry_run]
end

def set_rename_spec!(options)
  options[:rename_spec] = {}

  {
    const: '(\A|\\\\\w|[\W\da-z])%s(?:(?=[\W\dA-Z])|\z)',
    ident: '(\A|\\\\\w|[\W_])%s(?:(?=[\W\d_])|\z)',
  }.each do |type, fmt|
    options[:rename_spec][type] = spec = {}

    [true, false].each do |pluralize|
      word = options[:old]
      repl = options[:new]
      if pluralize
        word = word.pluralize
        repl = repl.pluralize
      end
      if type == :ident
        word = word.underscore
        repl = repl.underscore
      end

      r = Regexp.quote(word)
      spec[Regexp.new(fmt%r)] = repl
    end
  end
end

def gsub_by_rename_spec(str, options, types = [:const, :ident])
  [types].flatten.each do |type|
    options[:rename_spec][type].each do |reg, rep|
      str = str.gsub(reg) { $1 + rep }
    end
  end
  str
end

def match_by_rename_spec(str, options, types = [:const, :ident])
  [types].flatten.any? do |type|
    options[:rename_spec][type].any? do |reg, rep|
      reg =~ str
    end
  end
end

module FakeActiveRecordSchema
  OPTIONS = {}

  module ActiveRecord
    class Schema

      class CreateTable
        def initialize
          @columns = {}
        end

        def apply(&block)
          instance_eval(&block)
          @columns
        end

        def method_missing(type, column_name, opts = {})
          @columns[column_name] = opts.merge(column_type: type)
        end
      end

      def initialize(opts)
        @options = opts
        @operations = {
          rename_table: [],
          rename_column: [],
          remove_index: [],
          add_index: [],
        }
      end
      attr_reader :operations

      def self.define(opts, &block)
        new(opts).apply(&block)
      end

      def apply(&block)
        instance_eval(&block)
        self
      end

      def __match(str)
        match_by_rename_spec(str, OPTIONS, :ident)
      end

      def __gsub(str)
        gsub_by_rename_spec(str, OPTIONS, :ident)
      end

      def create_table(table_name, opts, &block)
        if __match(table_name)
          old_name = table_name
          table_name = __gsub(table_name)
          @operations[:rename_table] << [old_name, table_name]
        end

        ct = CreateTable.new
        cols = ct.apply(&block)
        cols.keys.each do |name|
          next unless __match(name)
          @operations[:rename_column] << [table_name, name, __gsub(name)]
        end
      end

      def add_index(table_name, columns, opts = {})
        new_table = new_columns = nil
        if __match(table_name)
          new_table = __gsub(table_name)
        end
        if columns.any? {|col| __match(col) }
          new_columns = columns.map {|col| __gsub(col) }
        end

        if new_table || new_columns
          @operations[:remove_index] << [table_name, columns, opts]
          new_opts = opts.dup
          new_opts.delete(:name)
        end

        if new_table && new_columns
          @operations[:add_index] << [new_table, new_columns, new_opts]
        elsif new_table
          @operations[:add_index] << [new_table, columns, new_opts]
        elsif new_columns
          @operations[:add_index] << [table_name, new_columns, new_opts]
        end
      end
    end
  end

  def migration(path, name, options)
    OPTIONS.replace(options.dup)
    result = eval(File.read(path))
    ops = result.operations

    up = []
    dw = []

    ops[:remove_index].map do |old_table, old_cols, old_opts|
      ocs = old_cols.map {|t| ":#{t}" }.join(', ')
      oos = old_opts.map {|k, v| ":#{k} => #{v.inspect}" }.join(', ')
      up << "remove_index :#{old_table}, [#{ocs}]"
      dw <<    "add_index :#{old_table}, [#{ocs}]#{oos.empty? ? '' : ', ' + oos}"
    end

    ops[:rename_table].map do |old_table, new_table|
      up << "rename_table :#{old_table}, :#{new_table}"
      dw << "rename_table :#{new_table}, :#{old_table}"
    end

    ops[:rename_column].map do |new_table, old_col, new_col|
      up << "rename_column :#{new_table}, :#{old_col}, :#{new_col}"
      dw << "rename_column :#{new_table}, :#{new_col}, :#{old_col}"
    end

    ops[:add_index].map do |new_table, new_cols, new_opts|
      ncs = new_cols.map {|t| ":#{t}" }.join(', ')
      nos = new_opts.map {|k, v| ":#{k} => #{v.inspect}" }.join(', ')
      up <<    "add_index :#{new_table}, [#{ncs}]#{nos.empty? ? '' : ', ' + nos}"
      dw << "remove_index :#{new_table}, [#{ncs}]"
    end

    dw.reverse!
    return nil if up.empty?

    <<-EOM
class #{name} < ActiveRecord::Migration
  def up
    #{up.join("\n    ")}
  end

  def down
    #{dw.join("\n    ")}
  end
end
    EOM
  end
  module_function :migration
end

def generate_migration(base_dir, options)
  db_dir = File.join(base_dir, 'db')
  schema_file = File.join(db_dir, 'schema.rb')
  return unless File.file?(schema_file)

  migration_name = "Rename#{options[:old]}To#{options[:new]}"
  migration_file = Time.now.strftime("%Y%m%d%H%M%S_#{migration_name.underscore}.rb")
  migration_path = File.join(db_dir, 'migrate', migration_file)

  script = FakeActiveRecordSchema.migration(schema_file, migration_name, options)
  return if script.nil?

  if options[:dry_run]
    if options[:verbose]
      puts "\# #{migration_path}"
      print script
    end
    return
  end

  create_proc = proc do
    open(migration_path, 'w') {|io| io.print script }
  end

  case options[:vcs]
  when :none
    puts "create #{path}" if options[:verbose]
    create_proc.call
  when :git
    create_proc.call
    git_cmd(['add', migration_path], options)
  end
end

def find_target(base_dir, type)
  base_dir = base_dir.sub(%r{/+\z/}, '')
  found = []
  return found unless File.directory?(base_dir)

  regexps = {
    include: [
      %r!^app/[^/]+/!,
      %r!^db/seeds\.rb!,
      %r!^db/fixtures/.*\.yml!,
      %r!^spec/[^/]+/!,
      %r!^test/[^/]+/!,
      %r!^lib/!,
      %r!^config/!,
      %r!^script/!,
      %r!^report/.*\.tlf$!,
      %r!^examples/!,
    ],
    exclude: [
      %r!^script/rails!,
      %r!^config/database\.yml!,
      %r!^config/boot\.rb!,
      %r!^db/migrate!,
      %r!^spec/dummy!,
      %r!\.git!,
      %r!^\.!, %r!/\.!,
    ],
  }

  text_exts = %w(
    html js css csv
    xml atom rdf rss tlf
    txt text yml yaml
    scss sass coffee builder
    rb erb rake
  )

  unless [:file, :text_file, :dir].include?(type)
    raise ArgumentError
  end

  reg_prefix = %r!^#{Regexp.quote(base_dir)}/!
  Find.find(base_dir) do |path|
    next if type == :dir && !File.directory?(path)
    next if (type == :file || type == :text_file) && !File.file?(path)
    next if type == :text_file &&
      /\.(?:#{text_exts.map {|e| Regexp.quote(e) }.join('|')})(?:\.|\z)/o !~ File.basename(path)

    p = path.sub(reg_prefix, '')
    next if regexps[:exclude].any? {|reg| reg =~ p }
    next unless regexps[:include].any? {|reg| reg =~ p }

    found << path
  end

  found
end

def do_rename_file(path, new_path, options)
  case options[:vcs]
  when :none
    FileUtils.mv(path, new_path, verbose: options[:verbose], noop: options[:dry_run])
  when :git
    git_cmd(['mv', path, new_path], options)
  end
end

def rename_files(base_dir, options)
  [:dir, :file].each do |type|
    find_target(base_dir, type).each do |path|
      new_path = gsub_by_rename_spec(path, options, :ident)
      next if new_path == path
      do_rename_file(path, new_path, options)
    end
  end
end

def do_replace_content(path, content, new_content, options)
  if options[:dry_run]
    return unless options[:verbose]
    require 'fileutils'
    require 'tmpdir'

    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path + '.orig', 'w') {|io| io.print content }
        File.open(path, 'w') {|io| io.print new_content }
        system 'diff', '-u', path + '.orig', path
      end
    end

    return
  end

  replace_proc = proc do
    open(path, 'w') {|io| io.print new_content }
  end

  case options[:vcs]
  when :none
    FileUtils.cp(path, path + '.orig', preserve: true)
    puts "replace content of #{path}" if options[:verbose]
    replace_proc.call
  when :git
    replace_proc.call
    git_cmd(['add', path], options)
  end
end

def replace_contents(base_dir, options)
  find_target(base_dir, :text_file).each do |path|
    content = File.read(path)
    begin
      new_content = gsub_by_rename_spec(content, options)
      next if new_content == content
      do_replace_content(path, content, new_content, options)
    rescue
      raise $!, "#{$!.message} (#{path})"
    end
  end
end

def parse_argv!
  options = {verbose: false, dry_run: false, vcs: :none}
  OptionParser.new do |o|
    o.banner = "使い方: bundle exec rails runner #{$0} -- [オプション...]"
    o.separator ''

    o.on('--old=OldWord', '変更対象とする語を指定する(必須)') do |name|
      options[:old] = name
    end

    o.on('--new=NewWord', '変更後の語を指定する(必須)') do |name|
      options[:new] = name
    end

    o.on('--git', 'gitステージングする') do
      options[:vcs] = :git
    end

    o.on('--skip-rename', 'ファイル名を変更しない') do
      options[:skip_rename] = true
    end

    o.on('--skip-replace', 'ファイルの内容を変更しない') do
      options[:skip_replace] = true
    end

    o.on('--skip-migrate', 'マイグレーションを生成しない') do
      options[:skip_migrate] = true
    end

    o.on('--dry-run', '処理内容を表示して終了する') do
      options[:dry_run] = true
      options[:verbose] = true
    end

    o.on('--[no-]verbose', '処理経過を表示する') do |value|
      options[:verbose] = value
    end

    o.separator ''
    o.on_tail('--help', 'ヘルプを表示して終了する') do
      puts o
      exit
    end
  end.parse!(ARGV)

  unless options[:new] && options[:old]
    raise OptionParser::InvalidOption, '変更前、変更後のモデルクラス名を指定してください'
  end

  [:new, :old].each do |sym|
    name = options[sym]
    unless /\A[A-Z]/ =~ name
      raise OptionParser::InvalidOption, "大文字で始まるクラス名を指定してください(--#{sym})"
    end
  end

  set_rename_spec!(options)
  options
end

begin
  options = parse_argv!
  target = ARGV.shift || '.'
  Dir.chdir(target)

  unless options[:skip_rename]
    puts 'rename directries and files'
    rename_files('.', options)
    rename_files('spec/dummy', options)
    puts 'done.'
  end

  unless options[:skip_replace]
    puts 'replace contents'
    replace_contents('.', options)
    replace_contents('spec/dummy', options)
    puts 'done.'
  end

  unless options[:skip_migrate]
    puts 'generate migration'
    generate_migration('.', options)
    puts 'done.'
  end

rescue OptionParser::ParseError
  abort $!.message
end
