class ItemHasOperator < ActiveRecord::Base
  attr_accessible :created_at, :id, :item_id, :library_id, :note, :operated_at, :updated_at, :username, :_destroy
  attr_accessor :username

  default_scope :order => "operated_at, created_at"

  belongs_to :user
  belongs_to :item
  belongs_to :library

  validates_presence_of :item
  validates_presence_of :user
  validate :validate_user_id
  before_validation :set_user

  def set_user
    self.user = User.where(:username => self.username).first
  end

  def validate_user_id
    if self.username.present?
      user = User.where("username = ?",self.username).try(:first)
      unless user
        errors.add(:user, I18n.t('item_has_operators.no_matches_found_user', :user_number => self.username))
      else
        self.user_id = user.id
      end
    end
  end

end
