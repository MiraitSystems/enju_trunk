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
      begin
        unless value.instance_of? String
          value.each do |num, v|
            k = "#{key}[#{num}]"
            add_exinfo(k, v, manifestation_id, list, position)
          end
        else
          add_exinfo(key, value, manifestation_id, list, position)
        end
      rescue
        next
      end
    end
    return list
  end

  def self.add_exinfo(key, value, manifestation_id, list, position) 
    manifestation_exinfo = ManifestationExinfo.where(
      name: key,
      manifestation_id: manifestation_id
    ).first
    if manifestation_exinfo
      if value.blank?
        manifestation_exinfo.destroy
        raise
      else
        manifestation_exinfo.value = value
      end
    else
      raise if value.blank?
      manifestation_exinfo = ManifestationExinfo.new(
        name: key,
        value: value,
        manifestation_id: manifestation_id
      )
    end
    manifestation_exinfo.position = position
    manifestation_exinfo.save!
    list << manifestation_exinfo
    position += 1
  end
end
