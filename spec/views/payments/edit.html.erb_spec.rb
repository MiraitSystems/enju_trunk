require 'spec_helper'

describe "payments/edit" do
  before(:each) do
    @payment = assign(:payment, stub_model(Payment,
      :order_id => 1,
      :manifestation_id => 1,
      :currency_unit_code => 1,
      :currency_rate => "9.99",
      :discount_commision => "9.99",
      :before_conv_amount_of_payment => "9.99",
      :amount_of_payment => "9.99",
      :number_of_payment => 1,
      :volume_number => "MyString",
      :note => "MyText",
      :auto_calculation_flag => 1,
      :payment_type => 1
    ))
  end

  it "renders the edit payment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", payment_path(@payment), "post" do
      assert_select "input#payment_order_id[name=?]", "payment[order_id]"
      assert_select "input#payment_manifestation_id[name=?]", "payment[manifestation_id]"
      assert_select "input#payment_currency_unit_code[name=?]", "payment[currency_unit_code]"
      assert_select "input#payment_currency_rate[name=?]", "payment[currency_rate]"
      assert_select "input#payment_discount_commision[name=?]", "payment[discount_commision]"
      assert_select "input#payment_before_conv_amount_of_payment[name=?]", "payment[before_conv_amount_of_payment]"
      assert_select "input#payment_amount_of_payment[name=?]", "payment[amount_of_payment]"
      assert_select "input#payment_number_of_payment[name=?]", "payment[number_of_payment]"
      assert_select "input#payment_volume_number[name=?]", "payment[volume_number]"
      assert_select "textarea#payment_note[name=?]", "payment[note]"
      assert_select "input#payment_auto_calculation_flag[name=?]", "payment[auto_calculation_flag]"
      assert_select "input#payment_payment_type[name=?]", "payment[payment_type]"
    end
  end
end
