require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'create')
class Create < ActiveRecord::Base
  belongs_to :patron
  validates_associated :patron
  after_save :reindex
  after_destroy :reindex
  attr_accessible :create_type_id

  paginates_per 10

  has_paper_trail

  def reindex
    patron.try(:index)
    work.try(:index)
  end

  def self.add_creates(manifestation_id, patron_id, type_id = [], delflg = [], newflg = false)
    if manifestation_id.blank? or patron_id.blank?
      return nil
    end
    patron_id.each_with_index do |p_id, i|
      next if delflg[i] and newflg
      sel_clm = self.find(:first, :conditions => ["work_id=? and patron_id=?", manifestation_id, p_id]) if p_id
      if sel_clm
         if delflg[i]
            sel_clm.destroy
         else
           if type_id[i].present? && sel_clm.create_type_id != type_id[i]
              sel_clm.create_type_id = type_id[i]
              sel_clm.save
           end
         end
      else
         self.create(:work_id => manifestation_id, :patron_id => p_id, :create_type_id => type_id[i])
      end
    end
  end
end

# == Schema Information
#
# Table name: creates
#
#  id         :integer         not null, primary key
#  patron_id  :integer         not null
#  work_id    :integer         not null
#  position   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

