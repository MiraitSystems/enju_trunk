require 'spec_helper'

describe "payments/show" do
  before(:each) do
    @payment = assign(:payment, stub_model(Payment,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/3/)
    rendered.should match(/9.99/)
    rendered.should match(/9.99/)
    rendered.should match(/9.99/)
    rendered.should match(/9.99/)
    rendered.should match(/4/)
    rendered.should match(/Volume Number/)
    rendered.should match(/MyText/)
    rendered.should match(/5/)
    rendered.should match(/6/)
  end
end
