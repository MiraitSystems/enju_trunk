class ItemHasOperator < ActiveRecord::Base
  attr_accessible :created_at, :id, :item_id, :library_id, :note, :operated_at, :updated_at, :user_id, :user_number
  attr_accessor :user_number, :delete_flg

  belongs_to :user
  belongs_to :item
  belongs_to :library

  validates_presence_of :user_id, :if => :check_number_empty
  validates_presence_of :item_id
  before_validation :set_user

  def set_user
    self.user = User.where(:user_number => self.user_number).first
  end

  def check_number_empty
     self.user_number.empty?
  end

  validate :validate_user_id
  def validate_user_id
    if self.user_number.present?
      user = User.where("user_number = ?",self.user_number)
      if user.empty?
        errors.add(:user, I18n.t('item_has_operators.no_matches_found_user', :user_number => self.user_number))
      else
        self.user_id = user.first.id
      end
    end
  end

end
