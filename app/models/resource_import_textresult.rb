require 'axlsx'
class ResourceImportTextresult < ActiveRecord::Base
  attr_accessible :resource_import_textfile_id, :body, :error_msg, :extraparams, :failed

  default_scope :order => 'resource_import_textresults.id DESC'
  scope :file_id, proc{|file_id| where(:resource_import_textfile_id => file_id)}
  scope :failed, where(:manifestation_id => nil)

  belongs_to :resource_import_textfile
  belongs_to :manifestation
  belongs_to :item

  validates_presence_of :resource_import_textfile_id

  def self.generate_resource_import_textresult_list(resource_import_textresults, output_type, current_user, &block)
    threshold ||= Setting.background_job.threshold.export rescue nil

    # 出力件数の計算
    all_size = resource_import_textresults.count
    resource_import_textresults.map(&:extraparams).each do |extraparams|
      num = eval(extraparams)['row_num'] rescue nil
      all_size += num.to_i if num
    end
    if threshold && threshold > 0 && all_size > threshold
      # 指定件数以上のときにはバックグラウンドジョブにする。
      job_name = GenerateResourceImportTextresultListJob.generate_job_name
      Delayed::Job.enqueue GenerateResourceImportTextresultListJob.new(job_name, resource_import_textresults, output_type, current_user)
      output = OpenStruct.new
      output.result_type = :delayed
      output.job_name = job_name
      block.call(output)
      return
    end
    generate_resource_import_textresult_list_internal(resource_import_textresults, output_type, &block)
  end

  def self.generate_resource_import_textresult_list_internal(resource_import_textresults, output_type, &block)
    output = OpenStruct.new
    output.result_type = output_type == 'xlsx' ? :path : :data
    case output_type
    when 'tsv'
      output.data     = get_resource_import_textresults_tsv_csv(resource_import_textresults)
      output.filename = Setting.resource_import_textresults_print_tsv.filename 
    when 'csv'
      output.data     = get_resource_import_textresults_tsv_csv(resource_import_textresults)
      output.filename = Setting.resource_import_textresults_print_csv.filename
    when 'xlsx'
      output.path     = get_resource_import_textresults_excelx(resource_import_textresults)
      output.filename = Setting.resource_import_textresults_print_xlsx.filename 
    end
    block.call(output)
  end

  def self.get_resource_import_textresults_tsv_csv(resource_import_textresults)
    split = SystemConfiguration.get("set_output_format_type") ? "\t" : ","
    before_sheet_name = nil
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8")
    resource_import_textresults.sort.each do |result|
      next if (eval(result.extraparams)['not_read'] rescue nil)
      next if result.body.nil? and result.extraparams.nil?
      sheet_name   = eval(result.extraparams)['sheet']        rescue nil
      wrong_sheet  = eval(result.extraparams)['wrong_sheet']  rescue nil
      wrong_format = eval(result.extraparams)['wrong_format'] rescue nil

      if sheet_name and (sheet_name != before_sheet_name)
        data << "\n" + '"sheet_name: ' + sheet_name + "\"\n"
        before_sheet_name = sheet_name
      end
      if wrong_sheet
        read_wrong_sheet(result.extraparams, { data: data }) 
      elsif wrong_format
        read_wrong_format(eval(result.extraparams)['filename'], { data: data })
      else
        row = result.body.split("\t")
        data << '"' + row.join(%Q[\"#{split}\"]) +"\"\n"
        delete_article(result)
      end
    end
    return data
  end

  def self.get_resource_import_textresults_excelx(resource_import_textresults)
    # initialize
    out_dir = "#{Rails.root}/private/system/manifestations_list_excelx"
    excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{rand(10)}.xlsx"
    FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)

    extraprams_list = resource_import_textresults.sort.map{ |r| r.extraparams }.uniq

    logger.info "get_manifestation_list_excelx filepath=#{excel_filepath}"
    Axlsx::Package.new do |p|
      wb = p.workbook
      wb.styles do |s|
        default_style = s.add_style :font_name => Setting.manifestation_list_print_excelx.fontname
        extraprams_list.each do |extraparams|
          next if eval(extraparams)['not_read'] rescue nil
          sheet_name = eval(extraparams)['sheet'] rescue nil
          'Sheet1' unless sheet_name
          wb.add_worksheet(:name => sheet_name) do |sheet|
            wrong_sheet  = eval(extraparams)['wrong_sheet'] rescue nil
            wrong_format = eval(extraparams)['wrong_format'] rescue nil
            if wrong_sheet
              read_wrong_sheet(extraparams, { sheet: sheet, default_style: default_style })
            elsif wrong_format
              read_wrong_format(eval(extraparams)['filename'], { sheet: sheet, default_style: default_style })
            else
              results = resource_import_textresults.where(:extraparams => extraparams)
              results.sort.each do |result|
                unless result.body.nil?
                  row = result.body.split(/\t/)
                  sheet.add_row row, :style => Array.new(columns.size).fill(default_style)
                  delete_article(result)
                end
              end
            end
          end
        end
        p.serialize(excel_filepath)
      end
    end
    return excel_filepath
  end

  def self.read_wrong_sheet(extraparams, options = { sheet: nil, default_style: nil, data: nil })
    oo = Excelx.new(eval(extraparams)['filename'])
    sheet_name = eval(extraparams)['sheet'] rescue nil
    oo.default_sheet = sheet_name
    begin
      oo.first_row.upto(oo.last_row) do |row|
        begin
          datas = []
          oo.first_column.upto(oo.last_column) do |column|
            datas << oo.cell(row, column).to_s.strip
          end
          if options[:sheet]
            options[:sheet].add_row datas, :types => :string, :style => Array.new(columns.size).fill(options[:default_style])
          else
            split = SystemConfiguration.get("set_output_format_type") ? "\t" : ","
            options[:data] << '"' + datas.join(%Q[\"#{split}\"]) +"\"\n"
          end
        rescue
          if options[:sheet]
            sheet.add_row [], :types => :string, :style => Array.new(columns.size).fill(options[:default_style])
          else
            options[:data] << '""' + "\n"
          end
        end 
      end
    rescue
      if options[:sheet]
        options[:sheet].add_row [], :types => :string, :style => Array.new(columns.size).fill(options[:default_style])
      else
        options[:data] << "\n"
      end
    end
  end

  def self.read_wrong_format(filename, options = { sheet: nil, default_style: nil, data: nil })
    split = SystemConfiguration.get('set_output_format_type') ? "\t" : ","
    #file = Tsvfile_Adapter.new.open_import_file(filename)
    tempfile = Tempfile.new('resource_import_file')
    if Setting.uploaded_file.storage == :s3
      uploaded_file_path = open(self.resource_import.expiring_url(10)).path
    else
      uploaded_file_path = filename
    end
    open(uploaded_file_path) { |f|
      f.each{ |line| tempfile.puts(NKF.nkf('-w -Lu', line)) }
    }
    tempfile.close
    file = CSV.open(tempfile.path, :col_sep => split)
    file.each_with_index do|row, c|
      if options[:sheet]
        options[:sheet].add_row row, :style => Array.new(columns.size).fill(options[:default_style])
      else
        options[:data] << '"' + row.join(%Q[\"#{split}\"]) +"\"\n" 
      end
    end
    file.close
  end

  def self.delete_article(result)
    item = Item.find(result.item_id) rescue nil
    if item
      if item.manifestation.article?
        if item.reserve
          item.reserve.revert_request rescue nil
        end
        item.destroy
        result.item_id = nil
      end
    end
    manifestation = Manifestation.find(result.manifestation_id) rescue nil
    if manifestation
      if manifestation.items.size == 0
        manifestation.destroy
        result.manifestation_id = nil
      end
    end
    result.save!
  rescue => e
    logger.info "failed to destroy item: #{result.item_id}"
    logger.info e.message
  end

  class GenerateResourceImportTextresultListJob
    include Rails.application.routes.url_helpers
    include BackgroundJobUtils

    def initialize(name, textresults, output_type, user)
      @name        = name
      @textresults = textresults
      @output_type = output_type
      @user        = user
    end
    attr_accessor :name, :textresults, :output_type, :user

    def perform
      user_file = UserFile.new(user)
      ResourceImportTextresult.generate_resource_import_textresult_list_internal(textresults, output_type) do |output|
        io, info = user_file.create(:resource_import_results, output.filename)
        if output.result_type == :path
          open(output.path) { |io2| FileUtils.copy_stream(io2, io) }
        else
          io.print output.data
        end
        io.close

        url = my_account_url(:filename => info[:filename], :category => info[:category], :random => info[:random])
        message(
          user,
          I18n.t('manifestation.output_job_success_subject', :job_name => name),
          I18n.t('manifestation.output_job_success_body', :job_name => name, :url => url))
      end
    rescue => exception
      message(
        user,
        I18n.t('manifestation.output_job_error_subject', :job_name => name),
        I18n.t('manifestation.output_job_error_body', :job_name => name, :message => exception.message+exception.backtrace))
    end
  end
end

# == Schema Information
#
# Table name: resource_import_results
#
#  id                      :integer         not null, primary key
#  resource_import_file_id :integer
#  manifestation_id        :integer
#  item_id                 :integer
#  body                    :text
#  created_at              :datetime
#  updated_at              :datetime
#

