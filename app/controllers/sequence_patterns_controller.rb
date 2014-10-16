class SequencePatternsController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.sequence_pattern'))", 'sequence_patterns_path', only: [:index]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.sequence_pattern'))", 'new_sequence_pattern_path', only: [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.sequence_pattern'))", 'edit_sequence_pattern_path(params[:id])', only: [:edit, :update]

  load_and_authorize_resource  
  before_filter :prepare_options, :except => [:index, :destroy]

  def index
    @sequence_patterns = SequencePattern.page(params[:page])
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
    @sequence_types = Keycode.where("name = ? AND (started_at <= ? OR started_at IS NULL) AND (? <= ended_at OR ended_at IS NULL)",
      'sequence_pattern.sequence_type', Time.zone.now, Time.zone.now) rescue nil
  end

end
