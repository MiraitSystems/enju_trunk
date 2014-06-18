# -*- encoding: utf-8 -*-
class Tsvfile_Adapter < EnjuTrunk::ResourceAdapter::Base
  attr_accessor :import_id

  def self.display_name
    "#{SystemConfiguration.get('set_output_format_type') ? 'TSV' : 'CSV'}ファイル"
  end

  def self.template_filename_show
    "tsvfile_show.html.erb"
  end

  def self.template_filename_edit
   "tsv_csvfile_edit.html.erb"
  end

  def check_format(filename)
    if filename.match(/.tsv$/)
      unless SystemConfiguration.get('set_output_format_type')
        raise I18n.t('resource_import_textfile.error.wrong_format')
      end
    else
      if SystemConfiguration.get('set_output_format_type')
        raise I18n.t('resource_import_textfile.error.wrong_format')
      end
    end
  end

  def open_import_file(filename)
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

    col_sep = SystemConfiguration.get('set_output_format_type') ? "\t" : ","
    file = CSV.open(tempfile.path, :col_sep => col_sep)

    unless block_given?
      return file
    end

    begin
      yield(file)
    ensure
      file.close
    end
  end
end
EnjuTrunk::ResourceAdapter::Base.add(Tsvfile_Adapter)
