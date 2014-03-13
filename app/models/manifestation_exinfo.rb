class ManifestationExinfo < ActiveRecord::Base
  attr_accessible :manifestation_id, :name, :position, :value, :manifestation

  acts_as_list
  default_scope :order => "position"

  belongs_to :manifestation

  has_paper_trail

  def self.add_exinfos(exinfos, manifestation_id)
    return [] if exinfos.blank?
    list = []
    position = 1
    exinfos.each do |key, value|
      manifestation_exinfo = ManifestationExinfo.where(
          name: key,
          manifestation_id: manifestation_id
        ).first

      if manifestation_exinfo
        if value.blank?
          manifestation_exinfo.destroy
          next
        else
          manifestation_exinfo.value = value
        end
      else
        next if value.blank?
        manifestation_exinfo = ManifestationExinfo.new(
          name: key,
          value: value,
          manifestation_id: manifestation_id
        )
      end
      manifestation_exinfo.position = position
      manifestation_exinfo.save
      list << manifestation_exinfo
      position += 1
    end
    return list
  end
end
