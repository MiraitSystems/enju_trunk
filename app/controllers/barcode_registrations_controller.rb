class BarcodeRegistrationsController < ApplicationController
  respond_to :html, :json
  #load_and_authorize_resource

  def index
    first_number = params[:first_number]
    last_number = params[:last_number]

    unless (first_number.blank? || last_number.blank?)
      unless (first_number =~ /\D/ || last_number =~ /\D/ || (first_number > last_number) || (first_number.length > 9) || (last_number.length > 9))
        first = first_number.to_i
        last = last_number.to_i
      
        respond_to do |format|

          columns = [
            [:barcode, 'activerecord.attributes.patron.full_name'],
          ]
          data = String.new
          data << "\xEF\xBB\xBF".force_encoding("UTF-8") #+ "\n"
          #data << "\xEF\xBB\xBF".encode("Shift_JIS") #+ "\n"
          row = []
          columns.each do |column|
            row << I18n.t(column[1])
          end
          data << '"'+row.join("\",\"")+"\"\n"
          row = []
          first.upto(last) do |num|
            row << "%09d" % num
          end
          data << '"'+row.join("\",\n\"")+"\"\n"
        
          send_data data, :filename => Setting.barcode_output.filename + ".csv"
          return
        end
      else
        @first = params[:first_number]
        @last = params[:last_number]
        render :action => "index"
      end
    else
      @first = params[:first_number] unless first_number.blank?
      @last = params[:last_number] unless last_number.blank?
      render :action => "index"
    end
  end
end

