class Order < ActiveRecord::Base

  attr_accessible :order_identifier, :manifestation_id, :buying_payment_year, :prepayment_settlements_of_account_year, :paid_flag, :number_of_acceptance_schedule, :meeting_holding_month_1, :meeting_holding_month_2, :adption_code, :deliver_place_code_1, :deliver_place_code_2, :deliver_place_code_3, :application_form_code_1, :application_form_code_2, :number_of_acceptance, :number_of_missing, :collection_status_code, :reason_for_collection_stop_code, :collection_stop_day, :order_form_code, :collection_form_code, :payment_form_code, :budget_subject_code, :transportation_route_code, :bookstore_code, :currency_id, :currency_rate, :margin_ratio, :original_price, :cost, :order_organization_id, :note, :group, :pair_manifestation_identifier, :unit_price, :taxable_amount, :tax_exempt_amount, :total_payment,:ordered_at, :order_year, :reference_code_id, :publisher_type_id

  attr_accessor :pair_manifestation_identifier

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
  has_many :items

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
  before_validation :set_pair_manifestation
  validates_presence_of :pair_manifestation_id, :unless => proc{self.pair_manifestation_identifier.blank?}, :message => I18n.t('activerecord.errors.attributes.order.pair_manifestation_identifier.not_found') 

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

  def set_pair_manifestation
    return if self.pair_manifestation_identifier.blank?
    if manifestation = Manifestation.where(:identifier => self.pair_manifestation_identifier).try(:first)
      self.pair_manifestation = manifestation
    end
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

  def create_manifestations(with_item = TRUE)
    ordered_manifestation = self.manifestation
    new_manifestations = []
    num = self.number_of_acceptance_schedule
    if self.manifestation.periodical_master
      series_statement = ordered_manifestation.series_statement
      m_issue = series_statement.last_issue
      last_volume = m_issue.volume_number
      last_issue = m_issue.issue_number
      last_serial = m_issue.serial_number
      num.times do
        new_m = series_statement.new_manifestation
        new_m.set_next_number(last_volume, last_issue)
        new_m.serial_number = last_serial + 1  rescue nil
        new_m.serial_number_string = new_m.serial_number.to_s rescue nil
        new_m.save!
        new_manifestations << new_m
        last_volume = new_m.volume_number; last_issue = new_m.issue_number; last_serial = new_m.serial_number
      end
      new_manifestations.map {|m| create_item(m)} if with_item
    else
      num.times { create_item(ordered_manifestation) } if with_item
      new_manifestations << ordered_manifestation
    end

    return new_manifestations
  end

  def create_item(manifestation)
    item = Item.new
    item.circulation_status = CirculationStatus.find_by_name('On Order') || CirculationStatus.first
    #TODO default checkout_type
    item.checkout_type = CheckoutType.first
    item.manifestation = manifestation
    item.order_id = self.id
    item.save
  end

  paginates_per 10

  # update number_of_acceptance
  # create payments 
  def update_order
    order = self
    acquired_num = order.items.where('acquired_at IS NOT NULL').size rescue 0
    order.number_of_acceptance = acquired_num
    order.save
    if order.payment_form.v == '1' || order.payment_form.v == '3' #TODO only prepayment
      ordered_items = order.items.where('acquired_at IS NOT NULL AND payment_id IS NULL')
      ordered_items.each do |item|
        payment = Payment.new(:order_id => order.id)
        payment.billing_date = Time.now
        payment.manifestation_id = item.manifestation.id #TODO
        payment.currency_id = order.currency_id
        payment.currency_rate = order.currency_rate
        payment.discount_commision = order.margin_ratio
        payment.before_conv_amount_of_payment = order.original_price
        payment.amount_of_payment = order.unit_price
#        payment.taxable_amount = order.taxable_amount
#        payment.tax_exempt_amount = order.tax_exempt_amount
        payment.number_of_payment = 1 
        payment.payment_type = 2 #TODO
        payment.save!
        item.update_attributes(:payment_id => payment.id)
      end
    end 
  end 

  def self.ouput_columns
    return [{name:"number", model: "calculate", column: "calculate"},
            {name:"full_name", model: "agents", column: "full_name"},
            {name:"zip_code_1", model: "agents", column: "zip_code_1"},
            {name:"address_1", model: "agents", column: "address_1"},
            {name:"country_of_publication_id", model: "manifestations", column: "country_of_publication_id"},
            {name:"date_of_publication", model: "manifestations", column: "date_of_publication"},
            {name:"bookstore_code", model: "orders", column: "bookstore_code"},
            {name:"collection_status_code", model: "orders", column: "collection_status_code"},
            {name:"currency_id", model: "orders", column: "currency_id"},
            {name:"edition", model: "manifestations", column: "edition"},
            {name:"frequency_id", model: "manifestations", column: "frequency_id"},
            {name:"currency_rate", model: "orders", column: "currency_rate"},
            {name:"discount_commision", model: "orders", column: "discount_commision"},
            {name:"group", model: "orders", column: "group"},
            {name:"order_note", model: "orders", column: "note"},
            {name:"prepayment_principal_rate", model: "calculate", column: "calculate"},
            {name:"number_of_acceptance", model: "orders", column: "number_of_acceptance"},
            {name:"number_of_acceptance_schedule", model: "orders", column: "number_of_acceptance_schedule"},
            {name:"identifier", model: "manifestations", column: "identifier"},
            {name:"issn", model: "manifestations", column: "issn"},
            {name:"number_of_missing", model: "orders", column: "number_of_missing"},
            {name:"order_identifier", model: "orders", column: "order_identifier"},
            {name:"pair_manifestation_id", model: "orders", column: "pair_manifestation_id"},
            {name:"issue_number_string", model: "manifestations", column: "issue_number_string"},
            {name:"report_number_string", model: "manifestations", column: "issue_number_string"},
            {name:"original_title", model: "manifestations", column: "original_title"},
            {name:"publishers", model: "manifestations", column: "publishers"},
            {name:"volume_number_string", model: "manifestations", column: "volume_number_string"},
            {name:"report_volume_number_string", model: "manifestations", column: "volume_number_string"},
            {name:"acquired_at", model: "items", column: "acquired_at_string"},
            {name:"quantity", model: "calculate", column: "calculate"},
            {name:"payment_form_code", model: "orders", column: "payment_form_code"},
            {name:"prepayment_principal", model: "orders", column: "prepayment_principal"},
            {name:"publication_year", model: "orders", column: "publication_year"},
            {name:"tax_exempt_amount", model: "orders", column: "tax_exempt_amount"},
            {name:"taxable_amount", model: "orders", column: "taxable_amount"},
            {name:"item_note", model: "items", column: "note"},
            {name:"transportation_route_code", model: "orders", column: "transportation_route_code"},
            {name:"yen_imprest", model: "orders", column: "yen_imprest"},
            {name:"deduction_quantity", model: "calculate", column: "calculate"},
            {name:"delayed_quantity", model: "calculate", column: "calculate"}
           ]
  end

  def self.document_application_columns
    return ["full_name","zip_code_1","address_1","order_note","identifier","original_title"]
  end

  def self.list_of_order_columns
    return ["number","country_of_publication_id","bookstore_code","currency_id","frequency_id","currency_rate",
            "discount_commision","group","order_note","prepayment_principal_rate","identifier","issn",
            "order_identifier","pair_manifestation_id","original_title","publishers","payment_form_code",
            "prepayment_principal","transportation_route_code","yen_imprest"]
  end

  def self.list_of_deferred_payment_acceptance_columns
    return ["number","date_of_publication","bookstore_code","currency_id","edition",
            "currency_rate","discount_commision","group","identifier","order_identifier",
            "issue_number_string","report_number_string","original_title","volume_number_string",
            "report_volume_number_string","acquired_at ","quantity","prepayment_principal",
            "publication_year","transportation_route_code","yen_imprest"]
  end

  def self.list_of_acceptance_situation_columns
    return ["date_of_publication","bookstore_code","collection_status_code","edition","frequency_id",
            "group","order_note","number_of_acceptance","number_of_acceptance_schedule","identifier",
            "issn","number_of_missing","issue_number_string","report_number_string","original_title",
            "publishers","volume_number_string","acquired_at ","publication_year","item_note"]
  end

  def self.list_of_payment_columns
    return ["country_of_publication_id","bookstore_code","collection_status_code","currency_id","frequency_id",
            "currency_rate","discount_commision","group","number_of_acceptance","number_of_acceptance_schedule",
            "identifier","issn","number_of_missing","order_identifier","original_title","publishers","payment_form_code",
            "prepayment_principal","publication_year","tax_exempt_amount","taxable_amount","yen_imprest",
            "deduction_quantity","delayed_quantity"]
  end

  def self.list_of_acceptance_after_payment_columns
    return ["date_of_publication","bookstore_code","edition","group","identifier","order_identifier",
            "issue_number_string","report_number_string","original_title","volume_number_string",
            "acquired_at ","publication_year","transportation_route_code"]
  end

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

