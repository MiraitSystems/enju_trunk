class RelationshipFamily < ActiveRecord::Base
  default_scope :order => 'id desc'
  attr_accessible :description, :display_name, :note
  has_many :series_statement_relationships
  has_many :series_statements, :through => :series_statement_relationships

  validates_presence_of :display_name

  paginates_per 10

  searchable do
    text :display_name, :description, :note
  end
  
end
