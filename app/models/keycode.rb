class Keycode < ActiveRecord::Base
  attr_accessible :display_name, :ended_at, :keyname, :name, :started_at, :v
  validates_presence_of :name, :display_name, :v, :keyname, :started_at
  validates_format_of :name, :with => /^[0-9A-Za-z]/ #, :message =>"は半角英数字で入力してください。"
  validate :validate_term
  default_scope where(:hidden => false)
  default_scope :order => 'name ASC, started_at ASC'

  has_many :agents
  has_many :orders
  has_many :approvals

  paginates_per 10

  def validate_term
    unless self.ended_at.nil?
      unless self.started_at < self.ended_at
        errors.add(:base, I18n.t('activerecord.attributes.keycode.ended_at_invalid'))
      end
    end
  end
end
