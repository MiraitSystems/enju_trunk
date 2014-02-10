class Payment < ActiveRecord::Base
  attr_accessible :amount_of_payment, :auto_calculation_flag, :before_conv_amount_of_payment, :billing_date, :currency_rate, :currency_unit_code, :discount_commision, :manifestation_id, :note, :number_of_payment, :order_id, :payment_type, :volume_number

  paginates_per 10
end
