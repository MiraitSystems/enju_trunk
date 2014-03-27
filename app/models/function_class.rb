class FunctionClass < ActiveRecord::Base
  attr_accessible :display_name, :name, :position
  has_many :function_class_abilities, :dependent => :destroy
  has_many :user

  default_scope :order => 'position'
  acts_as_list

  validates :name, presence: true
  validates :display_name, presence: true

  validates_uniqueness_of :name

  def self.noclass_id
    where(name: 'noclass').first.try(:id)
  end

  def self.nobody_id
    where(name: 'nobody').first.try(:id)
  end
end
