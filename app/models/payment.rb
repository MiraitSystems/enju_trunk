class Payment < ActiveRecord::Base
  attr_accessible :amount_of_payment, :auto_calculation_flag, :before_conv_amount_of_payment, :billing_date, :currency_rate, :currency_id, :discount_commision, :manifestation_id, :note, :number_of_payment, :order_id, :payment_type, :volume_number, :taxable_amount, :tax_exempt_amount

  belongs_to :order
  belongs_to :manifestation
  belongs_to :currency

  validates :discount_commision, :numericality => true
  validates :before_conv_amount_of_payment, :numericality => true
  validates :number_of_payment, :numericality => true
  validates :currency_rate, :numericality => true, :if => "auto_calculation_flag == 1"
  validates :amount_of_payment, :numericality => true, :if => "auto_calculation_flag == 1"

  validates :payment_type, :numericality => true
  validates :taxable_amount, :numericality => true
  validates :tax_exempt_amount, :numericality => true

  validate :validate_deferred_payment
  def validate_deferred_payment
    if self.payment_type == 2 && self.auto_calculation_flag == 0
      errors.add(:base, I18n.t('payment.no_create_deferred_payment')) if Payment.where(["order_id = ? AND payment_type = 3", self.order_id]).empty?
    end
  end


  before_validation :set_default
  def set_default
    if self.currency_rate.blank? && self.auto_calculation_flag != 1
      self.currency_rate = 0.0 
    else
      self.currency_rate = BigDecimal("#{self.currency_rate}").floor(2)
    end

    if self.discount_commision.blank?
      self.discount_commision = 1.0 
    else
      self.discount_commision = BigDecimal("#{self.discount_commision}").floor(3)
    end

    self.before_conv_amount_of_payment = 0 if self.before_conv_amount_of_payment.blank?
    self.amount_of_payment = 0 if self.amount_of_payment.blank? && self.auto_calculation_flag != 1
    self.number_of_payment = 0 if self.number_of_payment.blank?
 
    self.taxable_amount = 0 if self.taxable_amount.blank?
    self.tax_exempt_amount = 0 if self.tax_exempt_amount.blank?

  end



  before_save :set_amount_of_payment
  def set_amount_of_payment
    if self.auto_calculation_flag != 1

      case self.payment_type
        when 1
          calculation_advance_payment
        when 2
          calculation_deferred_payment
        else
      end
    end
  end

  def calculation_advance_payment
      date = Date.today
      date = self.billing_date unless self.billing_date.blank?

      exchangerate = ExchangeRate.find(:first, :order => "started_at DESC", :conditions => ["currency_id = ? and started_at <= ?", self.currency_id, date])

      if exchangerate
        self.currency_rate = exchangerate.rate
      else
        self.currency_rate = 1
      end

      if self.currency_id == 28
        self.amount_of_payment = (self.currency_rate * self.discount_commision * self.before_conv_amount_of_payment).to_i
      else
        self.amount_of_payment = (((self.currency_rate * self.discount_commision * 100).to_i / 100.0) * self.before_conv_amount_of_payment).to_i
      end
  end


  def calculation_deferred_payment
    paid = Payment.where(["payment_type = 3 AND order_id = ?",self.order_id]).order("billing_date DESC, id DESC").first
    if paid
      self.taxable_amount = (paid.taxable_amount / paid.number_of_payment) * self.number_of_payment if paid.number_of_payment != 0
      self.tax_exempt_amount = (paid.tax_exempt_amount / paid.number_of_payment) * self.number_of_payment if paid.number_of_payment != 0

      self.amount_of_payment = self.taxable_amount + self.tax_exempt_amount
    end
  end

  after_save :calculation_total_payment
  after_destroy :calculation_total_payment
  def calculation_total_payment
    order = Order.find(self.order_id)
    order.calculation_total_payment
  end


  def self.create_paid(order_id)
    @paid = Payment.new
    
    @paid.order_id = order_id
    @paid.payment_type = 3
    @paid.billing_date = Date.today
    @paid.auto_calculation_flag = 1

    @order = Order.find(order_id)
    @paid.manifestation_id = @order.manifestation_id

    @payments = Payment.where(:order_id => order_id)

    payment_taxable_amount = 0
    payment_tax_exempt_amount = 0
    payment_number_of_payment = 0
    @payments.each do |p|
      if p.payment_type != 3
        payment_taxable_amount += p.taxable_amount
        payment_tax_exempt_amount += p.tax_exempt_amount
        payment_number_of_payment += p.number_of_payment
      end
    end

    @paid.taxable_amount = @order.taxable_amount - payment_taxable_amount
    @paid.tax_exempt_amount = @order.tax_exempt_amount - payment_tax_exempt_amount
    @paid.amount_of_payment = @paid.taxable_amount + @paid.tax_exempt_amount
    @paid.number_of_payment = @order.number_of_acceptance_schedule - payment_number_of_payment

    @paid.save

    return @paid

  end

  def self.create_advance_payment(order_id)

  order = Order.find(order_id)

  @payment = Payment.new(:order_id => order_id)
  @payment.billing_date = order.order_day
  @payment.manifestation_id = order.manifestation_id
  @payment.currency_id = order.currency_id
  @payment.currency_rate = order.currency_rate
  @payment.discount_commision = order.discount_commision
  @payment.before_conv_amount_of_payment = order.prepayment_principal
  @payment.amount_of_payment = order.yen_imprest
  @payment.taxable_amount = order.taxable_amount
  @payment.tax_exempt_amount = order.tax_exempt_amount
  @payment.number_of_payment = order.number_of_acceptance_schedule
  @payment.auto_calculation_flag = order.auto_calculation_flag
  @payment.payment_type = 1

  @payment.save

  end


  paginates_per 10

end
