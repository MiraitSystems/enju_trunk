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
      keycode = Keycode.where(:name => "manifestation.#{key}", :keyname => value['value']).try(:first)
      if manifestation_exinfo
        if value.blank?
          manifestation_exinfo.destroy
          next
        else
          if keycode
            manifestation_exinfo.value = keycode.id
          else
            manifestation_exinfo.value = value['value']
          end
        end
      else
        next if value.blank?
        if keycode
          manifestation_exinfo = ManifestationExinfo.new(
            name: key,
            value: keycode.id,
            manifestation_id: manifestation_id
          )
        else
          manifestation_exinfo = ManifestationExinfo.new(
            name: key,
            value: value['value'],
            manifestation_id: manifestation_id
          )
        end
      end
      manifestation_exinfo.position = position
      manifestation_exinfo.save
      list << manifestation_exinfo
      position += 1
    end
    return list
  end
end
