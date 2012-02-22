class PatronImportFilesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource

  # GET /patron_import_files
  # GET /patron_import_files.xml
  def index
    @patron_import_files = PatronImportFile.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @patron_import_files }
    end
  end

  # GET /patron_import_files/1
  # GET /patron_import_files/1.xml
  def show
    if @patron_import_file.patron_import.path
      unless configatron.uploaded_file.storage == :s3
        file = @patron_import_file.patron_import.path
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @patron_import_file }
      format.download {
        if configatron.uploaded_file.storage == :s3
          redirect_to @patron_import_file.patron_import.expiring_url(10)
        else
          send_file file, :filename => @patron_import_file.patron_import_file_name, :type => 'application/octet-stream'
        end
      }
    end
  end

  # GET /patron_import_files/new
  # GET /patron_import_files/new.xml
  def new
    @patron_import_file = PatronImportFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @patron_import_file }
    end
  end

  # GET /patron_import_files/1/edit
  def edit
  end

  # POST /patron_import_files
  # POST /patron_import_files.xml
  def create
    @patron_import_file = PatronImportFile.new(params[:patron_import_file])
    @patron_import_file.user = current_user

    respond_to do |format|
      if @patron_import_file.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.patron_import_file'))
        format.html { redirect_to(@patron_import_file) }
        format.xml  { render :xml => @patron_import_file, :status => :created, :location => @patron_import_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @patron_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /patron_import_files/1
  # PUT /patron_import_files/1.xml
  def update
    respond_to do |format|
      if @patron_import_file.update_attributes(params[:patron_import_file])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.patron_import_file'))
        format.html { redirect_to(@patron_import_file) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @patron_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /patron_import_files/1
  # DELETE /patron_import_files/1.xml
  def destroy
    @patron_import_file.destroy

    respond_to do |format|
      format.html { redirect_to(patron_import_files_url) }
      format.xml  { head :ok }
    end
  end

  def import_request
    begin
      @patron_import_file = PatronImportFile.find(params[:id])
      Asynchronized_Service.new.delay.perform(:PatronImportFile_import, @patron_import_file.id)
      flash[:message] = t('patron_import_file.start_importing')
    rescue Exception => e
      logger.error "Failed to send process to delayed_job: #{e}"
    end
    respond_to do |format|
      format.html {redirect_to(patron_import_file_patron_import_results_path(@patron_import_file))}
    end
  end


end
