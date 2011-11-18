class BarcodeListsController < ApplicationController
#  load_and_authorize_resource

  # GET /barcode_lists
  # GET /barcode_lists.xml
  def index
    @barcode_lists = BarcodeList.paginate(:page => params[:page])
    @start_rows = params[:start_rows]
    @start_cols = params[:start_cols]

    if params[:mode] == 'barcode_list'
      render :action => 'barcode_list', :layout => false
      return
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @barcode_lists }
    end
  end

  # GET /barcode_lists/1
  # GET /barcode_lists/1.xml
  def show
    @barcode_list = BarcodeList.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @barcode_list }
      format.svg { send_data @barcode_list.data, :type => 'image/svg+xml', :disposition => 'inline' }
    end
  end

  # GET /barcode_lists/new
  # GET /barcode_lists/new.xml
  def new
    @barcode_list = BarcodeList.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @barcode }
    end
  end

  # GET /barcode_lists/1/edit
  def edit
    @barcode_list = BarcodeList.find(params[:id])
  end

  # POST /barcode_lists/1
  # POST /barcode_lists/1.xml
  def update
    @barcode_list = BarcodeList.find(params[:id])

    respond_to do |format|
      if params[:start_number] =~ /^[0-9]+$/ && params[:print_sheet] =~ /^[0-9]+$/
        pdf = @barcode_list.create_pdf_sheet(params[:start_number],params[:print_sheet])
        @new_last = (params[:start_number].to_i - 1) + @barcode_list.sheet_type * params[:print_sheet].to_i
        if @new_last >= @barcode_list.last_number
          @barcode_list.last_number = @new_last  
        end
        if @barcode_list.save && pdf
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.barcode_list'))
#          format.html { redirect_to(@barcode_list) }
          format.html { redirect_to :action => 'show_pdf', :id => @barcode_list, :status => 301}
          format.xml  { head :ok }
        else
          @barcode_list.errors.add_to_base t('activerecord.attributes.barcode_list.error')
          format.html { render :action => "edit" }
          format.xml  { render :xml => @barcode_list.errors, :status => :unprocessable_entity }
        end
      else
        @barcode_list.errors.add_to_base t('activerecord.attributes.barcode_list.error')
        format.html { render :action => "edit" }
        format.xml  { render :xml => @barcode_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show_pdf
    id = params[:id]
    path = "#{RAILS_ROOT}/private/system/barcode_list/#{id}/original/barcode.pdf"
    send_file(path, :type => "application/pdf")
  end

  # DELETE /barcode_lists/1
  # DELETE /barcode_lists/1.xml
  def destroy
    @barcode_list = BarcodeList.find(params[:id])
    @barcode_list.deleted_at = Time.now
    @barcode_list.save

    respond_to do |format|
      format.html { redirect_to(barcode_lists_url) }
      format.xml  { head :ok }
    end
  end
end
