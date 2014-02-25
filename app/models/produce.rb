require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'produce')
class Produce < ActiveRecord::Base
  attr_accessible :produce_type_id
  has_paper_trail

  def self.add_produces(manifestation_id, agent_id, type_id = [], delflg = [], newflg = false)
    if manifestation_id.blank? or agent_id.blank?
      return nil
    end
    agent_id.each_with_index do |p_id, i|
      next if delflg[i] and newflg
      sel_clm = self.find(:first, :conditions => ["manifestation_id=? and agent_id=?", manifestation_id, p_id]) if p_id
      if sel_clm
         if delflg[i]
            sel_clm.destroy
         else
           if type_id[i].present? && sel_clm.produce_type_id != type_id[i]
              sel_clm.produce_type_id = type_id[i]
              sel_clm.save
           end
         end
      else
         self.create(:manifestation_id => manifestation_id, :agent_id => p_id, :produce_type_id => type_id[i])
      end
    end
  end
end

