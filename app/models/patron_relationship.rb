class PatronRelationship < ActiveRecord::Base
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Patron'
  belongs_to :child, :foreign_key => 'child_id', :class_name => 'Patron'
  belongs_to :patron_relationship_type
  validate :check_parent
  validates_presence_of :parent_id, :child_id
  acts_as_list :scope => :parent_id
  scope :seealso_type, where(:patron_relationship_type_id => 1)
  scope :member_type, where(:patron_relationship_type_id => 2)
  scope :child_type, where(:patron_relationship_type_id => 3)
  after_save :reindex
  after_destroy :reindex

  def check_parent
    errors.add(:parent) if parent_id == child_id
    existing_record = PatronRelationship.find(:first, :conditions => ["parent_id = ? AND child_id = ?", child_id, parent_id])
    unless existing_record.blank?
      errors.add(:parent)
    end
  end

  def reindex
    self.parent.index
    self.child.index
  end

  def self.count_relationship(patron_id, relation_type_id)
    return 0 if patron_id.blank?
    if relation_type_id.blank?
      self.where("parent_id = ? OR child_id = ?", patron_id, patron_id).count
    else
      self.where("(parent_id = ? OR child_id = ?) AND patron_relationship_type_id = ?", patron_id, patron_id, relation_type_id).count
    end
  end
end

# == Schema Information
#
# Table name: patron_relationships
#
#  id                          :integer         not null, primary key
#  parent_id                   :integer
#  child_id                    :integer
#  patron_relationship_type_id :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  position                    :integer
#

