# encoding: utf-8
class KeywordCount < ActiveRecord::Base
  validates_uniqueness_of :date, :scope => [:keyword]
  attr_accessible :count, :date, :keyword

  # def self.calc(date = (Time.now).to_s)
  def self.calc(date = (Time.now - 1.day).to_s)
    require "time"
    date = Time.parse(date).strftime("%Y-%m-%d") rescue nil
    return puts "KeywordCount> wrong date" if date == nil

    puts "KeywordCount> start calcu for a keyword count: #{date}"
    word = Struct.new(:query, :count)
    words = SystemConfiguration.get("write_search_log_to_file") ? calc_file(word, date) : calc_db(word, date)

    begin
      words.each do |word, count|
        keyword_count = KeywordCount.new
        keyword_count.date = date
        keyword_count.keyword = word.query
        keyword_count.count = word.count
        keyword_count.save!
      end
    rescue Exception => e
      logger.error e
      p e
    end
  end 

  def self.create_ranks(start_d, end_d)
    datas = []
    error =  ApplicationController.helpers.term_check(start_d, end_d)
    return datas, error unless error.blank?

    data = Struct.new(:rank, :keyword, :count)
    logs = KeywordCount.find(:all,
      :select     => "keyword, sum(count) as count",
      :group      => "keyword",
      :conditions => ["date >= ? AND date <= ?", start_d.gsub(/\D/, ''), end_d.gsub(/\D/, '')],
      :order      => "sum(count) desc, keyword asc")
    num = 0
    rank = 0
    before_count = 0;
    logs.each do |log|
      num += 1;
      rank = num unless before_count == log.count
      datas << data.new(rank, log.keyword, log.count)
      before_count = log.count
    end
    return datas, nil
  end

  private
  def self.calc_file(word, date)
    require "find"
    #directory = "#{Rails.root}/log" # <= if use all file of search.log
    file = "#{Rails.root}/log/search.log"

    words = []
    #Find.find(directory) do |file|     
      #if /^search/ =~ File.basename(file)
        File.open(file, 'r') do |file|
          while line = file.gets
            if /^#{date}/ =~ line.encode("UTF-8", "UTF-8", invalid: :replace, undef: :replace, replace: '.')
              query = line.split(/\t/)[1]
              unless query == ''
                #if words#words.inject([]){ |queries, query| queries << query }.
                if area = words.index{ |word| word.query == query } 
                  words[area].count += 1
                else
                  words << word.new(query, 1)
                end
              end
            end
          end          
        end
      #end
    #end
    return words
  end

  def self.calc_db(word, date)
    words = SearchHistory.find(:all,
      :select     => "query, count(query) as count",
      :group      => "query",
      :conditions => ["to_char(created_at, 'YYYY-MM-DD') <= ? AND query != ''", date]
    ).collect{ |s| word.new(s.query, s.count) }
    return words
  end

  def self.make_split_csv(all_results)
    split = ","
    get_keyword_counts_list(all_results, split) 
  end

  def self.make_split_tsv(all_results)
    split = "\t"
    get_keyword_counts_list(all_results, split) 
  end

  def self.get_keyword_counts_list_excelx(all_results)
    require 'axlsx'

    # initialize
    out_dir = "#{Rails.root}/private/system/keyword_counts_list_excelx"
    excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{rand(10)}.xlsx"
    FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)

    logger.info "get_manifestation_list_excelx filepath=#{excel_filepath}"

    Axlsx::Package.new do |p|
      wb = p.workbook
      wb.styles do |s|
        sheet = wb.add_worksheet(:name => 'count_rank')
        # ヘッダー部分
        columns = [
          [:rank,'activerecord.attributes.keyword_count.rank'],
          [:keyword, 'activerecord.attributes.keyword_count.keyword'],
          [:count, 'activerecord.attributes.keyword_count.count'],
        ]
        row = columns.map {|column| I18n.t(column[1])}

        default_style = s.add_style :font_name => Setting.keyword_counts_list_print_excelx.fontname
        sheet.add_row row, :types => :string, :style => default_style
        # データ部分
        all_results.each do |result|
          data = []
          data << result.rank
          data << result.keyword
          data << result.count
          sheet.add_row data, :types => :string, :style => default_style
        end 
        p.serialize(excel_filepath)
      end
    end
    return excel_filepath
  end

  def self.get_keyword_counts_list(all_results, split)
    data = String.new

    # header
    data << "\xEF\xBB\xBF".force_encoding("UTF-8")
    columns = [
      [:rank,'activerecord.attributes.keyword_count.rank'],
      [:keyword, 'activerecord.attributes.keyword_count.keyword'],
      [:count, 'activerecord.attributes.keyword_count.count'],
    ]
    row = columns.map {|column| I18n.t(column[1])}
    data << '"'+row.join("\"#{split}\"")+"\"\n"

    # data
    all_results.each do |result|
      row = []
      columns.each do |column|
        case column[0]
        when :rank
          row << result.rank
        when :keyword
          row << result.keyword
        when :count
          row << result.count
        end
      end
      data << '"'+row.join("\"#{split}\"")+"\"\n"
    end
    return data
  end
end
