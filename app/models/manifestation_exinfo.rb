class ManifestationExinfo < ActiveRecord::Base
  attr_accessible :manifestation_id, :name, :position, :value, :manifestation

  acts_as_list :scope => [:manifestation_id, :name]
  default_scope :order => "position"

  belongs_to :manifestation
  belongs_to :keycode, class_name: "Keycode", foreign_key: :value

  has_paper_trail

  def self.add_exinfos(exinfos, manifestation_id)
    return [] if exinfos.blank?
    list = []
    exinfos.each do |key, value|
      name = key.split('_').first
      kid = key.split('_').last.to_i + 1
      manifestation_exinfo = ManifestationExinfo.where(
          name: name,
          manifestation_id: manifestation_id,
          position: kid
        ).first
      keycode = Keycode.where(:name => "manifestation.#{name}", :keyname => value['value']).try(:first)
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
          manifestation_exinfo = ManifestationExinfo.create(
            name: name,
            value: keycode.id,
            manifestation_id: manifestation_id,
            position: position
          )
        else
          manifestation_exinfo = ManifestationExinfo.create(
            name: name,
            value: value['value'],
            manifestation_id: manifestation_id,
            position: kid
          )
        end
      end
      list << manifestation_exinfo
    end
    return list
  end
end
