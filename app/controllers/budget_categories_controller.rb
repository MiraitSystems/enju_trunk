class BudgetCategoriesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def index
    @budget_categories = BudgetCategory.all
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

end
