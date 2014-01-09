class Keycode < ActiveRecord::Base
  attr_accessible :display_name, :ended_at, :keyname, :name, :started_at, :v
  validates_presence_of :name, :display_name, :v, :keyname, :started_at
  validates_format_of :name, :with => /^[0-9A-Za-z]/ #, :message =>"は半角英数字で入力してください。"
  default_scope :order => 'name ASC, started_at ASC'

  paginates_per 10

  def validate
    unless self.started_at < self.ended_at
      errors.add(:base, I18n.t('activerecord.attributes.keycode.ended_at_invalid'))
    end
  end
end
