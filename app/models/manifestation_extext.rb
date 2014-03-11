class ManifestationExtext < ActiveRecord::Base
  attr_accessible :manifestation_id, :name, :display_name, :position, :value
 
  belongs_to :manifestation

  acts_as_list
  default_scope :order => "position"

  has_paper_trail

  def self.add_extexts(extexts, manifestation_id)
    return [] if extexts.blank?
    list = []
    position = 1

    extexts.each do |key, value|
      begin
        unless value.instance_of? String
          value.each do |num, v|
            k = "#{key}[#{num}]"
            add_extext(k, v, manifestation_id, list, position)
          end
        else
          add_extext(key, value, manifestation_id, list, position)
        end
      rescue
        next
      end
    end
    return list
  end

  def self.add_extext(key, value, manifestation_id, list, position)
    manifestation_extext = ManifestationExtext.where(
      name: key,
      manifestation_id: manifestation_id
    ).first
    if manifestation_extext
      if value.blank?
        manifestation_extext.destroy
        raise
      else
        manifestation_extext.value = value
      end
    else
      raise if value.blank?
      manifestation_extext = ManifestationExtext.new(
        name: key,
        value: value,
        manifestation_id: manifestation_id
      )
    end
    manifestation_extext.position = position
    manifestation_extext.save!
    list << manifestation_extext
    position += 1
  end
end
