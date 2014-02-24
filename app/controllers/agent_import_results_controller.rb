class AgentImportResultsController < InheritedResources::Base
  add_breadcrumb "I18n.t('activerecord.models.agent_import_result')", 'agent_import_results_path'
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.agent_import_result'))", 'new_agent_import_result_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.agent_import_result'))", 'edit_agent_import_result_path([:id])', :only => [:edit, :update]
  respond_to :html, :json, :csv
  before_filter :check_client_ip_address
  before_filter :access_denied, :except => [:index, :show]
  load_and_authorize_resource
  has_scope :file_id

  def index
    @agent_import_file = AgentImportFile.where(:id => params[:agent_import_file_id]).first
    @agent_import_results = @agent_import_file.agent_import_results if @agent_import_file
    @results_num = @agent_import_results.length
    @agent_import_results = @agent_import_results.page(params[:page]) unless params[:format] == 'tsv' || params[:format] == 'csv'

    if (params[:format] == 'tsv' || params[:format] == 'csv')
      respond_to do |format|
        if SystemConfiguration.get("set_output_format_type") == false
          format.csv { send_data AgentImportResult.get_agent_import_results_tsv(@agent_import_results), :filename => Setting.agent_import_results_print_csv.filename } 
        else
          format.tsv { send_data AgentImportResult.get_agent_import_results_tsv(@agent_import_results), :filename => Setting.agent_import_results_print_tsv.filename } 
        end
      end
    end
  end
end
