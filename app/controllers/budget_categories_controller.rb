class BudgetCategoriesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource
  before_filter :prepare_options, :only => [:new, :edit]

  def index
    page = params[:page] || 1
    @budget_categories = Kaminari.paginate_array(BudgetCategory.all).page(page)
  end

  # GET /budget_categories/search_name.json
  def search_name
    struct_classification = Struct.new(:id, :text)
    if params[:budget_category_id]
      budget_category = BudgetCategory.where(id: params[:budget_category_id]).select("id, display_name, name").first
      result = struct_classification.new(budget_category.id, "#{budget_category.display_name}(#{budget_category.name})")
    else
      result = []
      budget_categories = params[:group_id].blank? ? BudgetCategory : BudgetCategory.where(:group_id => params[:group_id])
      budget_categories = budget_categories.where("name like '%#{params[:search_phrase]}%' OR display_name like '%#{params[:search_phrase]}%'")
                            .select("id, display_name, name").limit(10) || []
      budget_categories.each do |budget_category|
        result << struct_classification.new(budget_category.id, "#{budget_category.display_name}(#{budget_category.name})")
      end
    end
    respond_to do |format|
      format.json { render :text => result.to_json }
    end 
  end 

  def new
    @budget_category = BudgetCategory.new
  end

  def create
    @budget_category = BudgetCategory.new(params[:budget_category])

    respond_to do |format|
      if @budget_category.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.budget_category'))
        format.html { redirect_to(@budget_category) }
        format.json { render :json => @budget_category, :status => :created, :location => @budget_category }
      else
        format.html { render :action => "new" }
        format.json { render :json => @budget_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @budget_category = BudgetCategory.find(params[:id])
  end

  def update
    @budget_category = BudgetCategory.find(params[:id])
    if params[:move]
      move_position(@budget_category, params[:move])
      return
    end 
    respond_to do |format|
      if @budget_category.update_attributes(params[:budget_category])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.budget_category'))
        format.html { redirect_to(@budget_category) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @budget_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @budget_category = BudgetCategory.find(params[:id])
  end

  def destroy
    @budget_category = BudgetCategory.find(params[:id])
    respond_to do |format|
      if @budget_category.budgets.empty?
        @budget_category.destroy
        format.html { redirect_to(budget_categories_url) }
        format.json { head :no_content }
      else
        format.html { render :action => :index }
        format.json { render :json => @budget_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def prepare_options
    @budget_groups = Keycode.where(:name => 'budget_category.group') || []
  end

end
