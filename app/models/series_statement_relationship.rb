class SeriesStatementRelationship < ActiveRecord::Base
  SOURCES = { 0 => 'enju', 1 => 'NACSIS' } 
 
  default_scope :order => 'seq asc'
  attr_accessible :titleid, :series_statement_id, :relationship_family_id,
                  :fid, :seq, :bbid, :abid, :series_statement_relationship_type_id, :source,
                  :before_series_statement_relationship_id, :after_series_statement_relationship_id
  belongs_to :series_statement
  belongs_to :before_series_statement_relationship, :class_name => 'SeriesStatement'
  belongs_to :after_series_statement_relationship,  :class_name => 'SeriesStatement'
  belongs_to :series_statement_relationship_type
  belongs_to :relationship_family

  validates_presence_of :series_statement_id, :relationship_family_id, :seq, :series_statement_relationship_type_id, :source
  validates_length_of :before_series_statement_relationship_id, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 1 },
    :message => I18n.t('series_statement_relationship.not_necessary')
  validates_length_of :after_series_statement_relationship_id, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 5 },
    :message => I18n.t('series_statement_relationship.not_necessary')
  validates_length_of :bbid, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 1 and p.source == 1 },
    :message => I18n.t('series_statement_relationship.not_necessary')
  validates_length_of :abid, 
    :is => 0, 
    :if => proc { |p| p.series_statement_relationship_type_id.to_i == 5 and p.source == 1 },
    :message => I18n.t('series_statement_relationship.not_necessary')
end
