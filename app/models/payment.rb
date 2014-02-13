class Payment < ActiveRecord::Base
  attr_accessible :amount_of_payment, :auto_calculation_flag, :before_conv_amount_of_payment, :billing_date, :currency_rate, :currency_unit_code, :discount_commision, :manifestation_id, :note, :number_of_payment, :order_id, :payment_type, :volume_number, :taxable_amount, :tax_exempt_amount

  belongs_to :order
  belongs_to :paymenttype, :class_name => 'Keycode', :foreign_key => 'payment_type'


  validate :set_default

  validates :discount_commision, :numericality => true, :allow_blank => true
  validates :before_conv_amount_of_payment, :numericality => true, :allow_blank => true
  validates :number_of_payment, :numericality => true, :allow_blank => true

  validates :currency_rate, :numericality => true, :if => "auto_calculation_flag == 1"
  validates :amount_of_payment, :numericality => true, :if => "auto_calculation_flag == 1"

  validates :payment_type, :numericality => true

  validates :taxable_amount, :numericality => true, :allow_blank => true
  validates :tax_exempt_amount, :numericality => true, :allow_blank => true


  def set_default

    self.currency_rate = 0.0 if self.currency_rate.blank? && self.auto_calculation_flag != 1
    self.discount_commision = 1.0 if self.discount_commision.blank?
    self.before_conv_amount_of_payment = 0.0 if self.before_conv_amount_of_payment.blank?
    self.amount_of_payment = 0.0 if self.amount_of_payment.blank? && self.auto_calculation_flag != 1
    self.number_of_payment = 0.0 if self.number_of_payment.blank?
 
    self.taxable_amount = 0.0 if self.taxable_amount.blank?
    self.tax_exempt_amount = 0.0 if self.tax_exempt_amount.blank?

  end



  before_save :set_amount_of_payment

  def set_amount_of_payment

    if self.auto_calculation_flag != 1

      date = Date.today
      date = self.billing_date unless self.billing_date.blank?

      exchangerate = ExchangeRate.find(:first, :order => "started_at DESC", :conditions => ["currency_id = ? and started_at <= ?", self.currency_unit_code, date])

      if exchangerate
        self.currency_rate = exchangerate.rate
      else
        self.currency_rate = 1
      end

      if self.currency_unit_code == 28
        self.amount_of_payment = (self.currency_rate * self.discount_commision * self.before_conv_amount_of_payment).to_i
      else
        self.amount_of_payment = (((self.currency_rate * self.discount_commision * 100).to_i / 100.0) * self.before_conv_amount_of_payment).to_i
      end
    end

  end




  paginates_per 10
end
