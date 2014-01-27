class PatronMergeList < ActiveRecord::Base
  has_many :patron_merges, :dependent => :destroy
  has_many :patrons, :through => :patron_merges
  validates_presence_of :title

  paginates_per 10

  def merge_patrons(selected_patron)
    self.patrons.each do |patron|
      Create.where(:patron_id => patron.id).each do |create|
        create.update_attributes(:patron_id => selected_patron.id)
      end
      Realize.where(:patron_id => patron.id).each do |realize|
        realize.update_attributes(:patron_id => selected_patron.id)
      end
      Produce.where(:patron_id => patron.id).each do |produce|
        produce.update_attributes(:patron_id => selected_patron.id)
      end
      Own.where(:patron_id => patron.id).each do |own|
        own.update_attributes(:patron_id => selected_patron.id)
      end
      Donate.where(:patron_id => patron.id).each do |donate|
        donate.update_attributes(:patron_id => selected_patron.id)
      end
      patron.destroy unless patron == selected_patron
    end
  end
end

# == Schema Information
#
# Table name: patron_merge_lists
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

