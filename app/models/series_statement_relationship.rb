class SeriesStatementRelationship < ActiveRecord::Base
#  attr_accessible :child_id, :parent_id
#  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'SeriesStatement'
#  belongs_to :child, :foreign_key => 'child_id', :class_name => 'SeriesStatement'

  SOURCES = { 'enju' => 0, 'NACSIS' => 1 } 

  attr_accessible :titleid, :series_statement_id, :relationship_family_id,
                  :fid, :seq, :bbid, :abid, :series_statement_relationship_type_id, :source,
                  :before_series_statement_relationship_id, :after_series_statement_relationship_id
  belongs_to :series_statement
  belongs_to :before_series_statement_relationship, :class_name => 'SeriesStatement'
  belongs_to :after_series_statement_relationship,  :class_name => 'SeriesStatement'
  belongs_to :series_statement_relationship_type
  belongs_to :relationship_family

  validates_presence_of :series_statement_id, :relationship_family_id, :seq, :series_statement_relationship_type_id, :source
  validates_length_of :bbid, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 0 },
    :message => I18n.t('series_statement_relationship.not_necessary')
  validates_length_of :before_series_statement_relationship_id, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 0 },
    :message => I18n.t('series_statement_relationship.not_necessary')
  validates_length_of :after_series_statement_relationship_id, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 9 },
    :message => I18n.t('series_statement_relationship.not_necessary')
  validates_length_of :abid, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 9 },
    :message => I18n.t('series_statement_relationship.not_necessary')

  after_save :reindex
  after_destroy :reindex

  def reindex
  end

=begin
# TODO: 元のコード
  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :child_id, :scope => :parent_id
  acts_as_list :scope => :parent_id

  def reindex
    parent.try(:index)
    child.try(:index)
    Sunspot.commit
  end
=end
end
