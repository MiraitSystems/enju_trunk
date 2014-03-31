class Order < ActiveRecord::Base

  attr_accessible :order_identifier, :manifestation_id, :buying_payment_year, :prepayment_settlements_of_account_year, :paid_flag, :number_of_acceptance_schedule, :meeting_holding_month_1, :meeting_holding_month_2, :adption_code, :deliver_place_code_1, :deliver_place_code_2, :deliver_place_code_3, :application_form_code_1, :application_form_code_2, :number_of_acceptance, :number_of_missing, :collection_status_code, :reason_for_collection_stop_code, :collection_stop_day, :order_form_code, :collection_form_code, :payment_form_code, :budget_subject_code, :transportation_route_code, :bookstore_code, :currency_id, :currency_rate, :margin_ratio, :original_price, :cost, :order_organization_id, :note, :group, :pair_manifestation_id, :unit_price, :taxable_amount, :tax_exempt_amount, :total_payment,:ordered_at, :order_year, :reference_code_id, :publisher_type_id


  belongs_to :manifestation, :foreign_key => 'manifestation_id'
  belongs_to :pair_manifestation,:class_name => 'Manifestation', :foreign_key => 'pair_manifestation_id'
  belongs_to :collection_status, :class_name => 'Keycode', :foreign_key => 'collection_status_code'
  belongs_to :collection_form, :class_name => 'Keycode', :foreign_key => 'collection_form_code'


  belongs_to :deliver_place_1, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_1'
  belongs_to :deliver_place_2, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_2'
  belongs_to :deliver_place_3, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_3'
  belongs_to :application_form_1, :class_name => 'Keycode', :foreign_key => 'application_form_code_1'
  belongs_to :application_form_2, :class_name => 'Keycode', :foreign_key => 'application_form_code_2'

  belongs_to :paidflag, :class_name => 'Keycode', :foreign_key => 'paid_flag'
  belongs_to :adption, :class_name => 'Keycode', :foreign_key => 'adption_code'
  belongs_to :reason_for_collection_stop, :class_name => 'Keycode', :foreign_key => 'reason_for_collection_stop_code'
  belongs_to :order_form, :class_name => 'Keycode', :foreign_key => 'order_form_code'
  belongs_to :payment_form, :class_name => 'Keycode', :foreign_key => 'payment_form_code'
  belongs_to :budget_subject, :class_name => 'Keycode', :foreign_key => 'budget_subject_code'
  belongs_to :transportation_route, :class_name => 'Keycode', :foreign_key => 'transportation_route_code'
  belongs_to :bookstore, :class_name => 'Keycode', :foreign_key => 'bookstore_code'
  belongs_to :reference_code, :class_name => 'Keycode', :foreign_key => 'reference_code_id'
  belongs_to :publisher_type, :class_name => 'Keycode', :foreign_key => 'publisher_type_id'


  belongs_to :contract
  belongs_to :agent, :foreign_key => :order_organization_id
  belongs_to :currency

  has_many :payments

  validates :ordered_at, :presence => true
  validates :order_year, :numericality => true
  validates :buying_payment_year, :numericality => true, :allow_blank => true
  validates :prepayment_settlements_of_account_year, :numericality => true, :allow_blank => true
  validates :number_of_acceptance_schedule, :numericality => true
  validates :meeting_holding_month_1, :numericality => true, :allow_blank => true
  validates :meeting_holding_month_2, :numericality => true, :allow_blank => true
  validates :number_of_missing, :numericality => true
  validates :currency_rate, :numericality => true
  validates_numericality_of :margin_ratio, :greater_than => 0
  validates :original_price, :numericality => true, :allow_blank => true
  validates :cost, :numericality => true

  validates :collection_form_code, :presence => true
  validates :collection_status_code, :presence => true

  validates :taxable_amount, :numericality => true
  validates :tax_exempt_amount, :numericality => true
  validates :order_identifier, :presence => true, :uniqueness => true

  before_validation :set_default
  def set_default

    self.number_of_acceptance_schedule = 0 if self.number_of_acceptance_schedule.blank?
    self.number_of_missing = 0 if self.number_of_missing.blank?
    self.original_price = 0.0 if self.original_price.blank?

    if self.currency_rate.blank?
      self.currency_rate = 0.0
    else
      self.currency_rate = BigDecimal("#{self.currency_rate}").floor(2)
    end

    if self.margin_ratio.blank?
      self.margin_ratio = 1.00
    else
      self.margin_ratio = BigDecimal("#{self.margin_ratio}").floor(3)
    end

    self.cost = 0 if self.cost.blank?
    self.taxable_amount = 0 if self.taxable_amount.blank?
    self.tax_exempt_amount = 0 if self.tax_exempt_amount.blank?
  end


  def self.struct_agent_selects
    struct_agent = Struct.new(:id, :text)
    @struct_agent_array = []
    type_id = AgentType.find(:first, :conditions => ["name = ?", 'OrderOrganization'])
    struct_select = Agent.find(:all, :conditions => ["agent_type_id = ?",type_id])
    struct_select.each do |agent|
      @struct_agent_array << struct_agent.new(agent.id, agent.full_name)
    end
    return @struct_agent_array
  end

  def set_cost
      exchangerate = ExchangeRate.find(:first, :order => "started_at DESC", :conditions => ["currency_id = ? and started_at <= ?", self.currency_id, self.ordered_at])

      if exchangerate
        self.currency_rate = exchangerate.rate
      else
        self.currency_rate = 0
      end

      if self.currency_id == 28
        self.currency_rate = 1 if self.currency_rate == 0
        self.cost = (self.currency_rate * self.margin_ratio * self.original_price).to_i
      else
        self.cost = (((self.currency_rate * self.margin_ratio * 100).to_i / 100.0) * self.original_price).to_i
      end
  end

  before_save :set_created_at
  def set_created_at
    self.created_at = self.ordered_at
  end

  before_save :set_unit_price
  def set_unit_price
    if self.number_of_acceptance_schedule == 0
      self.unit_price = 0
    else
      begin
        self.unit_price = (self.cost / self.number_of_acceptance_schedule).to_i
      rescue
        self.unit_price = 0
      end
    end
  end

  def self.set_order_identifier(numbering_name = 'order')
    #numbering_name = "order_#{order_year}"
    begin
      identifier = Numbering.do_numbering(numbering_name)
    end while Order.where(:order_identifier => identifier).first
    return identifier
  end

  def create_payment_to_advance_payment

    if self.payment_form
      if self.payment_form.v == "1" || self.payment_form.v == "3"
        Payment.create_advance_payment(self.id)
        return true
      end
    end
  end

  before_create :create_total_payment
  def create_total_payment
    self.total_payment  =0
  end

  def calculation_total_payment
    payments = Payment.where("payment_type != 3 AND order_id = ?", self.id)

    self.total_payment = 0
    payments.each do |payment|
      self.total_payment += payment.amount_of_payment
    end
    self.save
  end


  def destroy?
    return false if Payment.where(:order_id => self.id).first
    return true
  end



  paginates_per 10


end

# == Schema Information
#
# Table name: orders
#
#  id                  :integer         not null, primary key
#  order_list_id       :integer         not null
#  purchase_request_id :integer         not null
#  position            :integer
#  state               :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#

