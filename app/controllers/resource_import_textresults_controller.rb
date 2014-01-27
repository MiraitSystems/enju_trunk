class ResourceImportTextresultsController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.resource_import_textresult'))", 
    'resource_import_textfile_resource_import_textresults_path(params[:resource_import_textfile_id])'
  respond_to :html, :json, :csv
  before_filter :access_denied, :except => [:index, :show]
  before_filter :check_client_ip_address
  load_and_authorize_resource
  has_scope :file_id

  def index
    @resource_import_textfile = ResourceImportTextfile.where(:id => params[:resource_import_textfile_id]).first
    if @resource_import_textfile
      if params[:only_error]
        @resource_import_textresults = @resource_import_textfile.resource_import_textresults.where(:failed => true)
      else
        @resource_import_textresults = @resource_import_textfile.resource_import_textresults
      end
    end
    @results_num = @resource_import_textresults.count
    if %w(tsv csv xlsx).include?(params[:type])
      do_file_output_proccess(@resource_import_textresults, params[:type]) and return
    else
      @resource_import_textresults = @resource_import_textresults.page(params[:page])
    end
  end

  def do_file_output_proccess(resource_import_textresults, format)
    ResourceImportTextresult.generate_resource_import_textresult_list(resource_import_textresults, format, current_user) do |output|
      send_opts = {
        :filename => output.filename,
        :type     => output.mime_type || 'application/octet-stream',
      }
      case output.result_type
      when :path
        send_file output.path, send_opts
      when :data
        send_data output.data, send_opts
      when :delayed
        flash[:message] = t('manifestation.output_job_queued', :job_name => output.job_name)
        redirect_to resource_import_textfile_resource_import_textresults_path(@resource_import_textfile)
      else
        msg = "unknown result type: #{output.result_type.inspect} (bug?)"
        logger.error msg
        raise msg
      end
    end
  end
end
