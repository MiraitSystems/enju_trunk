class SequencePatternsController < ApplicationController
  load_and_authorize_resource  
  before_filter :prepare_options, :except => [:index, :destroy]

  def index
    @sequence_patterns = SequencePattern.all
  end

  def new
    @sequence_pattern = SequencePattern.new
  end

  def edit
    @sequence_pattern = SequencePattern.find(params[:id])
  end

  def create
    @sequence_pattern = SequencePattern.new(params[:sequence_pattern])
    if @sequence_pattern.save
      flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.sequence_pattern'))
      redirect_to sequence_patterns_path 
    else
      render :action => "new" 
    end 
  end 

  def update
    @sequence_pattern = SequencePattern.find(params[:id])

    if @sequence_pattern.update_attributes(params[:sequence_pattern])
      flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.sequence_pattern'))
      redirect_to sequence_patterns_path
    else
      render :action => "edit" 
    end 
  end 

  def destroy
  end

private
  def prepare_options
    @sequence_types = SequencePattern.sequence_types
  end

end
