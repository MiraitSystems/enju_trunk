class TitleTypesController < ApplicationController
  load_and_authorize_resource

  def index
    @title_types = TitleType.page(params[:page]).order(:position)
  end

  def new
    @title_type = TitleType.new
  end

  def create
    @title_type = TitleType.new(params[:title_type])
     
    if TitleType.count != 0
      @title_type.position = TitleType.maximum('position') + 1
    else
      @title_type.position = 0
    end

    if @title_type.save
      flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.title_type'))
      redirect_to(@title_type) 
    else
      render :action => "new" 
    end
  end

  def edit
    @title_type = TitleType.find(params[:id])
  end

  def update
    @title_type = TitleType.find(params[:id])

    if @title_type.update_attributes(params[:title_type])
      flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.title_type'))
      redirect_to(@title_type) 
    else
      render :action => "edit" 
    end
  end

  def show
    @title_type = TitleType.find(params[:id])
  end

  def destroy
    @title_type = TitleType.find(params[:id]) 
    if @title_type.destroy?
      @title_type.destroy
      redirect_to(title_types_url) 
    else
      flash[:message] = t('title_type.cannot_delete')
      @title_types = TitleType.page(params[:page]).order(:position)
      redirect_to(title_types_url)
    end
  end

end

