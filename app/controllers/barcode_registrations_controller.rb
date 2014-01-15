class BarcodeRegistrationsController < ApplicationController
  add_breadcrumb "I18n.t('activemodel.models.barcode_registration')", 'barcode_registrations_path'
  load_and_authorize_resource
 
  def index
    @barcode_registration = BarcodeRegistration.new
  end

  def output
    @barcode_registration = BarcodeRegistration.new(params[:barcode_registration])
    if @barcode_registration.valid?
      data = BarcodeRegistration.set_data(@barcode_registration.first_number, @barcode_registration.last_number)
      send_data data, :filename => Setting.barcode_output.filename + ".csv"
    else
      render :action => :index
    end
  end
end

