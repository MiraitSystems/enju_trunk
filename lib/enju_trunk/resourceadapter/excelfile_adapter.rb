# -*- encoding: utf-8 -*-
class Excelfile_Adapter < EnjuTrunk::ResourceAdapter::Base

  def self.display_name
    "エクセルファイル(xlsx)"
  end

  def self.template_filename_select_manifestation_type
    "excelfile_select_manifestation_type.html.erb"
  end

  def set_field(oo, sheet, manifestation_type, field_row_num)
    raise I18n.t('resource_import_textfile.error.blank_sheet') unless oo.first_column
    # set field
    field = Hash::new
    files = []
    oo.first_column.upto(oo.last_column) do |column|
      name = oo.cell(field_row_num, column).to_s.strip
      unless name.blank?
        if field.keys.include?(name)
          raise I18n.t('resource_import_textfile.error.overlap')
        else
          field.store(name, column)
        end
      end
    end
    return field
  end
end
EnjuTrunk::ResourceAdapter::Base.add(Excelfile_Adapter)
