class AddColumnToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :order_identifier, :string, :null => false
    add_column :orders, :manifestation_id, :integer, :null => false
    add_column :orders, :order_day, :datetime, :null => false
    add_column :orders, :publication_year, :integer, :null => false
    add_column :orders, :buying_payment_year, :integer
    add_column :orders, :prepayment_settlements_of_account_year, :integer
    add_column :orders, :paid_flag, :integer
    add_column :orders, :number_of_acceptance_schedule, :integer, :default => 0, :null => false
    add_column :orders, :meeting_holding_month_1, :integer
    add_column :orders, :meeting_holding_month_2, :integer
    add_column :orders, :adption_code, :integer
    add_column :orders, :deliver_place_code_1, :integer
    add_column :orders, :deliver_place_code_2, :integer
    add_column :orders, :deliver_place_code_3, :integer
    add_column :orders, :deliver_place_code_4, :integer
    add_column :orders, :deliver_place_code_5, :integer
    add_column :orders, :application_form_code_1, :integer
    add_column :orders, :application_form_code_2, :integer
    add_column :orders, :number_of_acceptance, :integer, :default => 0, :null => false
    add_column :orders, :number_of_missing, :integer, :default => 0, :null => false
    add_column :orders, :collection_status_code, :integer, :null => false
    add_column :orders, :reason_for_collection_stop_code, :integer
    add_column :orders, :collection_stop_day, :datetime
    add_column :orders, :order_form_code, :integer
    add_column :orders, :collection_form_code, :integer, :null => false
    add_column :orders, :payment_form_code, :integer
    add_column :orders, :budget_subject_code, :integer
    add_column :orders, :transportation_route_code, :integer
    add_column :orders, :bookstore_code, :integer
    add_column :orders, :currency_unit_code, :integer
    add_column :orders, :currency_rate, :decimal, :default => 0, :null => false, :precision => 10, :scale => 2
    add_column :orders, :discount_commision, :decimal, :default => 1, :null => false, :precision => 10, :scale => 3
    add_column :orders, :reason_for_settlements_of_account_code, :integer
    add_column :orders, :prepayment_principal, :decimal, :default => 0, :null => false
    add_column :orders, :yen_imprest, :decimal, :default => 0, :null => false, :precision => 10, :scale => 2
    add_column :orders, :order_organization_id, :integer
    add_column :orders, :note, :text
    add_column :orders, :group, :string
    add_column :orders, :pair_manifestation_id, :integer
    add_column :orders, :contract_id, :integer
    add_column :orders, :unit_price, :decimal, :default => 0, :null => false
    add_column :orders, :auto_calculation_flag, :integer, :default => 0, :null => false
  end

end
