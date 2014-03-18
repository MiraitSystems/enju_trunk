class OutputColumnListsController < InheritedResources::Base
  before_filter :check_librarian
  #load_and_authorize_resource

  def index
    page = params[:page] || 1
    @output_column_lists = OutputColumnList.page(page)
  end

  def create
    @output_column_list = OutputColumnList.new(params[:output_column_list])
    respond_to do |format|
      if @output_column_list.save
        flash[:message] = t('controller.successfully_created', :model => t('activerecord.models.output_column_list'))
        format.html { redirect_to output_column_lists_path }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @output_column_list = OutputColumnList.find(params[:id])
    respond_to do |format|
      if @output_column_list.update_attributes(params[:output_column_list])
        flash[:message] = t('controller.successfully_updated', :model => t('activerecord.models.output_column_list'))
        format.html { redirect_to output_column_lists_path }
      else
        format.html { render :action => "edit" }
      end
    end
  end
end
