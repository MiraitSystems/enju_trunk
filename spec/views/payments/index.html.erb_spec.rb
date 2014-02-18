require 'spec_helper'

describe "payments/index" do
  before(:each) do
    assign(:payments, [
      stub_model(Payment,
        :order_id => 1,
        :manifestation_id => 2,
        :currency_unit_code => 3,
        :currency_rate => "9.99",
        :discount_commision => "9.99",
        :before_conv_amount_of_payment => "9.99",
        :amount_of_payment => "9.99",
        :number_of_payment => 4,
        :volume_number => "Volume Number",
        :note => "MyText",
        :auto_calculation_flag => 5,
        :payment_type => 6
      ),
      stub_model(Payment,
        :order_id => 1,
        :manifestation_id => 2,
        :currency_unit_code => 3,
        :currency_rate => "9.99",
        :discount_commision => "9.99",
        :before_conv_amount_of_payment => "9.99",
        :amount_of_payment => "9.99",
        :number_of_payment => 4,
        :volume_number => "Volume Number",
        :note => "MyText",
        :auto_calculation_flag => 5,
        :payment_type => 6
      )
    ])
  end

  it "renders a list of payments" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "9.99".to_s, :count => 2
    assert_select "tr>td", :text => "9.99".to_s, :count => 2
    assert_select "tr>td", :text => "9.99".to_s, :count => 2
    assert_select "tr>td", :text => "9.99".to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
    assert_select "tr>td", :text => "Volume Number".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 5.to_s, :count => 2
    assert_select "tr>td", :text => 6.to_s, :count => 2
  end
end
