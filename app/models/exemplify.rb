require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'exemplify')
class Exemplify < ActiveRecord::Base
  attr_accessible :manifestation_id, :item_id, :position
  self.extend ItemsHelper
=begin
  validates_uniqueness_of :manifestation_id,
    # :if => proc { SystemConfiguration.where("keyname = manifestation.has_one_item").v == "true" }
    :if => proc { logger.error SystemConfiguration.get("manifestation.has_one_item");logger.error"############################";SystemConfiguration.get("manifestation.has_one_item") }
  validates_uniqueness_of :item_id,
    # :if => proc { SystemConfiguration.where("keyname = manifestation.has_one_item").v == "true" }
    :if => proc { logger.error SystemConfiguration.get("manifestation.has_one_item");logger.error"############################";SystemConfiguration.get("manifestation.has_one_item") }
=end
  has_paper_trail
end


