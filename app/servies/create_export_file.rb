class CreateExportFile
  def self.create_export_file(current_user, filename, header, rows, file_type = 'xlsx')
    user_file = UserFile.new(current_user)
    excel_filepath, excel_fileinfo = user_file.create(:export_file, filename)

    begin
      require 'axlsx_hack'
      ws_cls = Axlsx::AppendOnlyWorksheet
    rescue LoadError
      require 'axlsx'
      ws_cls = Axlsx::Worksheet
    end  
    pkg = Axlsx::Package.new
    wb = pkg.workbook
    sty = wb.styles.add_style :font_name => Setting.export_excel.fontname
    sheet = ws_cls.new(wb)

    sheet.add_row header, :types => :string, :style => [sty]*header.size

    rows.map {|row| sheet.add_row row, :types => :string, :style => [sty]*row.size}

    pkg.serialize(excel_filepath)
    [excel_filepath, excel_fileinfo]  
  end
end
