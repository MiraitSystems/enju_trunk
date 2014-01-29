require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'realize')
class Realize < ActiveRecord::Base
  belongs_to :patron
  validates_associated :patron
  after_save :reindex
  after_destroy :reindex
  attr_accessible :realize_type_id

  paginates_per 10

  has_paper_trail

  def reindex
    patron.try(:index)
    expression.try(:index)
  end

  def self.add_realizes(manifestation_id, patron_id, type_id=[], delflg = [], newflg = false)
    if manifestation_id.blank? or patron_id.blank?
      return nil
    end
    patron_id.each_with_index do |p_id, i|
      next if delflg[i] and newflg
      sel_clm = self.find(:first, :conditions => ["expression_id=? and patron_id=?", manifestation_id, p_id]) if p_id
      if sel_clm
         if delflg[i]
            sel_clm.destroy
         else
           if type_id[i].present? && sel_clm.realize_type_id != type_id[i]
              sel_clm.realize_type_id = type_id[i]
              sel_clm.save
           end
         end
      else
         self.create(:expression_id => manifestation_id, :patron_id => p_id, :realize_type_id => type_id[i])
      end
    end
  end
end

# == Schema Information
#
# Table name: realizes
#
#  id            :integer         not null, primary key
#  patron_id     :integer         not null
#  expression_id :integer         not null
#  position      :integer
#  type          :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

