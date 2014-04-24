class Budget < ActiveRecord::Base

#  has_one :library
  belongs_to :term
  belongs_to :budget_type
  belongs_to :user
  has_many :expenses

#  validates_presence_of :library_id, :term_id
  validates_presence_of :name, :user_id, :budget_class
  validates_numericality_of :amount, :revised, :transferred, :allow_blank => true
  validates_presence_of :term_id, :if => proc{self.budget_class == "usual"}
  validates_presence_of :start_date, :end_date, :if => proc{self.budget_class == "provisional"}

  before_save :set_actual, :set_implementation, :set_estimated_implementation, :set_remaining
  
#  def library
#    Library.find(self.library_id) 
#  end
  
  def term
    Term.find(self.term_id)
  end

  def usual?
    return self.budget_class == "usual"
  end

  def provisional?
    return self.budget_class == "provisional"
  end

  def set_actual
    # 実予算額をセット
  end

  def set_implementation
    # 執行額をセット
  end

  def set_estimated_implementation
    # 執行予定額
  end

  def set_remaining
    # 残高
  end

end

