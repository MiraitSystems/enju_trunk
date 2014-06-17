# -*- encoding: utf-8 -*-
class Excelfile_Adapter < EnjuTrunk::ResourceAdapter::Base
  def self.display_name
    "エクセルファイル(xlsx)"
  end

  def self.template_filename_select_manifestation_type
    "excelfile_select_manifestation_type.html.erb"
  end
end
EnjuTrunk::ResourceAdapter::Base.add(Excelfile_Adapter)
