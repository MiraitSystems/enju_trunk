# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment do
    order_id 1
    billing_date "2014-02-10 17:12:26"
    manifestation_id 1
    currency_unit_code 1
    currency_rate "9.99"
    discount_commision "9.99"
    before_conv_amount_of_payment "9.99"
    amount_of_payment "9.99"
    number_of_payment 1
    volume_number "MyString"
    note "MyText"
    auto_calculation_flag 1
    payment_type 1
  end
end
