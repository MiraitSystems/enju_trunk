class ManifestationExtext < ActiveRecord::Base
  attr_accessible :manifestation_id, :name, :display_name, :position, :value, :type_id
 
  belongs_to :manifestation

  acts_as_list :scope => [:name, :type_id]
  default_scope :order => "position"

  has_paper_trail

  def self.add_extexts(extexts, manifestation_id)
    return [] if extexts.blank?
    list = []
    extexts.each do |key, value|
      next if value['value'].blank?
      name = key.split('_').first
      kid = key.split('_').last.to_i + 1
      manifestation_extext = ManifestationExtext.where(
        name: name,
        manifestation_id: manifestation_id,
        position: kid
      ).first
      if manifestation_extext
        if value['value'].blank?
          manifestation_extext.destroy
          next
        else
          manifestation_extext.value   = value['value']
          manifestation_extext.type_id = value['type_id']
        end
      else
        next if value['value'].blank?
        manifestation_extext = ManifestationExtext.create(
          name: name,
          value: value['value'],
          type_id: value['type_id'],
          manifestation_id: manifestation_id,
          position: kid
        )
      end
      list << manifestation_extext
    end
    return list
  end
end
