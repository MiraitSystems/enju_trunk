class StatisticalTableController < ApplicationController

  def index
    @statistical_table_types = [{:id => 'checkout_statistics', :display_name => '貸出統計表'},
                                {:id => 'item_statistics', :display_name => '蔵書統計表'}]
    @statistical_table_type = ''
  end
  
  def get_condition
    if params[:statistical_table_type] == 'checkout_statistics'
      @checkout_statistics = CheckoutStatistics.new(:statistical_table_type => params[:statistical_table_type])
      @classification_types = ClassificationType.all
      @first_aggregations = CheckoutStatistics.first_aggregations
      @second_aggregations = CheckoutStatistics.second_aggregations
      @default_date = Time.now.strftime("%Y-%m-%d")
      html = render_to_string :partial => 'checkout_statistics'
    end
    render :text => html
  end
  
  def output
    # 貸出統計表
    if params[:checkout_statistics].present?
      @checkout_statistics = CheckoutStatistics.new(params[:checkout_statistics])
      if @checkout_statistics.invalid?
        @statistical_table_types = [{:id => 'checkout_statistics', :display_name => '貸出統計表'},
                                    {:id => 'item_statistics', :display_name => '蔵書統計表'}]
        @statistical_table_type = 'checkout_statistics'
        @classification_types = ClassificationType.all
        @first_aggregations = CheckoutStatistics.first_aggregations
        @second_aggregations = CheckoutStatistics.second_aggregations
        @default_date = Time.now.strftime("%Y-%m-%d")
        render :action => 'index'
      else
        send_file CheckoutStatistics.output_excelx(@checkout_statistics.make_data), :filename => Setting.checkout_statistics_print_excelx.filename
      end
    end
  end

end
