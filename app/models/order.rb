class Order < ActiveRecord::Base

  attr_accessible :order_identifier, :manifestation_id, :order_day, :publication_year, :buying_payment_year, :prepayment_settlements_of_account_year, :paid_flag, :number_of_acceptance_schedule, :meeting_holding_month_1, :meeting_holding_month_2, :adption_code, :deliver_place_code_1, :deliver_place_code_2, :deliver_place_code_3, :deliver_place_code_4, :deliver_place_code_5, :application_form_code_1, :application_form_code_2, :number_of_acceptance, :number_of_missing, :collection_status_code, :reason_for_collection_stop_code, :collection_stop_day, :order_form_code, :collection_form_code, :payment_form_code, :budget_subject_code, :transportation_route_code, :bookstore_code, :currency_unit_code, :currency_rate, :discount_commision, :reason_for_settlements_of_account_code, :prepayment_principal, :yen_imprest, :order_organization_id, :note, :group, :pair_manifestation_id, :contract_id, :unit_price, :auto_calculation_flag, :taxable_amount, :tax_exempt_amount

  belongs_to :manifestation, :foreign_key => 'manifestation_id'
  belongs_to :pair_manifestation,:class_name => 'Manifestation', :foreign_key => 'pair_manifestation_id'
  belongs_to :collection_status, :class_name => 'Keycode', :foreign_key => 'collection_status_code'
  belongs_to :collection_form, :class_name => 'Keycode', :foreign_key => 'collection_form_code'


  belongs_to :deliver_place_1, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_1'
  belongs_to :deliver_place_2, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_2'
  belongs_to :deliver_place_3, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_3'
  belongs_to :deliver_place_4, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_4'
  belongs_to :deliver_place_5, :class_name => 'Keycode', :foreign_key => 'deliver_place_code_5'
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
  belongs_to :reason_for_settlements_of_account, :class_name => 'Keycode', :foreign_key => 'reason_for_settlements_of_account_code'


  belongs_to :contract
  belongs_to :patron, :foreign_key => :order_organization_id
  has_many :payments

  validate :set_default


  validates :order_day, :presence => true
  validates :publication_year, :numericality => true
  validates :buying_payment_year, :numericality => true, :allow_blank => true
  validates :prepayment_settlements_of_account_year, :numericality => true, :allow_blank => true
  validates :number_of_acceptance_schedule, :numericality => true, :allow_blank => true
  validates :meeting_holding_month_1, :numericality => true, :allow_blank => true 
  validates :meeting_holding_month_2, :numericality => true, :allow_blank => true
  validates :number_of_missing, :numericality => true, :allow_blank => true
  validates :currency_rate, :numericality => true, :if => "auto_calculation_flag == 1"
  validates_numericality_of :discount_commision, :greater_than => 0
  validates :prepayment_principal, :numericality => true, :allow_blank => true
  validates :yen_imprest, :numericality => true, :if => "auto_calculation_flag == 1"

  validates :collection_form_code, :presence => true
  validates :collection_status_code, :presence => true

  validates :taxable_amount, :numericality => true, :allow_blank => true
  validates :tax_exempt_amount, :numericality => true, :allow_blank => true

  validate :validate_manifestation

  def validate_manifestation
    unless self.manifestation_id
      errors.add(:base, I18n.t('order.no_matches_found_manifestation'))
    else
      unless Manifestation.find([self.manifestation_id])
      errors.add(:base, I18n.t('order.no_matches_found_manifestation'))
      end
    end
  end

  def set_default

    self.number_of_acceptance_schedule = 0 if self.number_of_acceptance_schedule.blank?
    self.number_of_missing = 0 if self.number_of_missing.blank?
    self.discount_commision = 1.0 if self.discount_commision.blank?
    self.prepayment_principal = 0.0 if self.prepayment_principal.blank?

    self.currency_rate = 0.0 if self.currency_rate.blank? && auto_calculation_flag != 1

    self.taxable_amount = 0.0 if self.taxable_amount.blank?
    self.tax_exempt_amount = 0.0 if self.tax_exempt_amount.blank?
  end


  def self.struct_patron_selects
    struct_patron = Struct.new(:id, :text)
    @struct_patron_array = []
    type_id = PatronType.find(:first, :conditions => ["name = ?", 'OrderOrganization'])
    struct_select = Patron.find(:all, :conditions => ["patron_type_id = ?",type_id])
    struct_select.each do |patron|
      @struct_patron_array << struct_patron.new(patron.id, patron.full_name)
    end
    return @struct_patron_array
  end

  before_save :set_yen_imprest

  def set_yen_imprest

    if self.auto_calculation_flag != 1

      exchangerate = ExchangeRate.find(:first, :order => "started_at DESC", :conditions => ["currency_id = ? and started_at <= ?", self.currency_unit_code, self.order_day])

      if exchangerate
        self.currency_rate = exchangerate.rate
      else
        self.currency_rate = 0
      end

      if self.currency_unit_code == 28
        self.yen_imprest = (self.currency_rate * self.discount_commision * self.prepayment_principal).to_i
      else
        self.yen_imprest = (((self.currency_rate * self.discount_commision * 100).to_i / 100.0) * self.prepayment_principal).to_i
      end
    end
 
    if self.number_of_acceptance_schedule == 0
      self.unit_price = 0
    else   
      begin
        self.unit_price = (self.yen_imprest / self.number_of_acceptance_schedule).to_i
      rescue
        self.unit_price = 0
      end
    end
  end

  before_create :set_order_identifier
  def set_order_identifier
    identifier = Numbering.do_numbering('order')

    if self.order_identifier != identifier
      identifier.slice!(0,4)
      self.order_identifier = self.order_identifier[0,4] + identifier
    end
  end

  def set_probisional_identifier(year = Date.today.year)

    @numbering = Numbering.find(:first, :conditions => {:numbering_type => 'order'})
    number = (((@numbering.last_number).to_i + 1).to_s).rjust(@numbering.padding_number,@numbering.padding_character.to_s);
    self.order_identifier = year.to_s + number

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

