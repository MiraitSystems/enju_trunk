# -*- encoding: utf-8 -*-
class SeriesStatementsController < ApplicationController
  add_breadcrumb "I18n.t('page.configuration')",
    'page_configuration_path'
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.series_statement'))",
    'series_statements_path'
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.series_statement'))", 
    'new_series_statement_path', 
    only: [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.series_statement'))", 
    'edit_series_statement_path([:id])', 
    only: [:edit, :update]
  add_breadcrumb "I18n.t('activerecord.models.series_statement')", 
    'series_statement_path([:id])', 
    only: [:show]

  load_and_authorize_resource
  before_filter :get_work, :only => [:index, :new, :edit]
  before_filter :get_manifestation, :only => [:index]
  before_filter :prepare_options, :only => [:new, :edit]
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  # GET /series_statements
  # GET /series_statements.json
  def index
    search = Sunspot.new_search(SeriesStatement)
    query = params[:query].to_s.strip
    page = params[:page] || 1
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
    end
    search.build do
      fulltext query if query.present?
      paginate :page => page.to_i, :per_page => SeriesStatement.default_per_page
      order_by :position, :asc
    end

    @basket = Basket.find(params[:basket_id]) if params[:basket_id]

    #work = @work
    manifestation = @manifestation
    unless params[:mode] == 'add'
      search.build do
      #  with(:work_id).equal_to work.id if work
        with(:manifestation_ids).equal_to manifestation.id if manifestation
      end
    end
    page = params[:page] || 1
    search.query.paginate(page.to_i, SeriesStatement.default_per_page)
    @series_statements = search.execute!.results

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @series_statements }
    end
  end

  # GET /series_statements/1
  # GET /series_statements/1.json
  def show
    respond_to do |format|
      if user_signed_in? and current_user.has_role?('Librarian')
        format.html   { redirect_to series_statement_manifestations_url(@series_statement, :all_manifEstations => true) }
        format.mobile { redirect_to series_statement_manifestations_url(@series_statement, :all_manifEstations => true) }
      else
        format.html   { redirect_to series_statement_manifestations_url(@series_statement) }
        format.mobile { redirect_to series_statement_manifestations_url(@series_statement) }
      end
      format.json { render :json => @series_statement }
      #format.js
    end
  end

  # GET /series_statements/new
  # GET /series_statements/new.json
  def new
    original_series_statement = SeriesStatement.find(params[:series_statement_id]) if params[:series_statement_id]
    if original_series_statement
      @series_statement = original_series_statement.dup
      @series_statement.root_manifestation = original_series_statement.root_manifestation.dup
      set_root_manifestation_instance_vals(original_series_statement.root_manifestation)
    else
      @series_statement.root_manifestation = Manifestation.new
    end
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @series_statement }
    end
  end

  # GET /series_statements/1/edit
  def edit
    @series_statement.work = @work if @work
    set_root_manifestation_instance_vals(@series_statement.root_manifestation)
  end

  # POST /series_statements
  # POST /series_statements.json
  def create
    SeriesStatement.transaction do
      @series_statement = SeriesStatement.new(params[:series_statement])
      @series_statement.root_manifestation = Manifestation.new(params[:manifestation])
      # set class instance variables, and create root_manifestation
      set_and_create_root_manifestation(params)
      @series_statement.save!
      @series_statement.manifestations << @series_statement.root_manifestation
      respond_to do |format|
        format.html { redirect_to series_statement_manifestations_path(@series_statement, :all_manifestations => true), 
          :notice => t('controller.successfully_created', :model => t('activerecord.models.series_statement')) }
        format.json { render :json => @series_statement, :status => :created, :location => @series_statement }
      end
    end
  rescue Exception => e
    logger.error "Failed to create: #{e}"
    prepare_options
    respond_to do |format|
      format.html { render :action => "new" }
      format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
    end
  end

  # PUT /series_statements/1
  def update
    SeriesStatement.transaction do
      if params[:move]
        move_position(@series_statement, params[:move])
        return
      end

      before_series_statement_periodical = @series_statement.periodical
      @series_statement.assign_attributes(params[:series_statement])
      @series_statement.root_manifestation.assign_attributes(params[:manifestation])

      # set class instance variables, and update root_manifestation
      set_and_create_root_manifestation(params)
      @series_statement.save!
      # reindex 
      if before_series_statement_periodical != @series_statement.periodical
        @series_statement.manifestations.update_all(periodical: @series_statement.periodical)
        Sunspot.index! @series_statement.manifestations
      end
      respond_to do |format|
        format.html { redirect_to series_statement_manifestations_path(@series_statement, :all_manifestations => true), 
          :notice => t('controller.successfully_updated', :model => t('activerecord.models.series_statement')) }
        format.json { head :no_content }
      end
    end
  rescue Exception => e
    logger.error "Failed to update: #{e}"
    prepare_options
    respond_to do |format|
      format.html { render :action => "edit" }
      format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
    end
  end

  # DELETE /series_statements/1
  # DELETE /series_statements/1.json
  def destroy
    SeriesStatement.transaction do
      @series_statement.root_manifestation.destroy
      @series_statement.destroy
      respond_to do |format|
        format.html { redirect_to series_statements_url }
        format.json { head :no_content }
      end
    end
  rescue => e
    logger.error "Failed to update: #{e}"
    respond_to do |format|
      format.html { redirect_to(series_statements_path) }
      format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
    end
  end

  def numbering
    manifestation_identifier = params[:type].present? ? Numbering.do_numbering(params[:type]) : nil 
    render :json => {:success => 1, :manifestation_identifier => manifestation_identifier}
  end 

  private
  def set_root_manifestation_instance_vals(root_manifestation)
    @series_work_has_languages = root_manifestation.work_has_languages
    @creates = root_manifestation.creates.order(:position)
    @realizes = root_manifestation.realizes.order(:position)
    @produces = root_manifestation.produces.order(:position)
    @subject = root_manifestation.subjects.collect(&:term).join(';')
    @subject_transcription = root_manifestation.subjects.collect(&:term_transcription).join(';')
    root_manifestation.manifestation_exinfos.
      each { |exinfo| eval("@#{exinfo.name} = '#{exinfo.value}'") } if root_manifestation.manifestation_exinfos
    root_manifestation.manifestation_extexts.
      each { |extext| eval("@#{extext.name} = '#{extext.value}'") } if root_manifestation.manifestation_extexts
  end

  def prepare_options
    @carrier_types = CarrierType.all
    @manifestation_types = ManifestationType.series
    @frequencies = Frequency.all
    @countries = Country.all
    @languages = Language.all_cache
    @language_types = LanguageType.all
    @roles = Role.all
    @create_types = CreateType.find(:all, :select => "id, name, display_name")
    @realize_types = RealizeType.find(:all, :select => "id, name, display_name")
    @produce_types = ProduceType.find(:all, :select => "id, name, display_name")
    @default_language = Language.where(:iso_639_1 => @locale).first
    @numberings = Numbering.get_manifestation_numbering('series_statement')
    @title_types = TitleType.find(:all, :select => "id, display_name", :order => "position")
    @work_manifestation = Manifestation.new
    @work_manifestation.work_has_titles = @series_statement.root_manifestation.work_has_titles if @series_statement.root_manifestation
    @use_licenses = UseLicense.all
    @sequence_patterns = SequencePattern.all
    @publication_statuses = PublicationStatus.all
    @creates = [] if @creates.blank?
    @realizes = [] if @realizes.blank?
    @produces = [] if @produces.blank?
    @del_creators = [] if @del_creators.blank?
    @del_contributors = [] if @del_contributors.blank?
    @del_publishers = [] if @del_publishers.blank?
    @add_creators = [{}] if @add_creators.blank?
    @add_contributors = [{}] if @add_contributors.blank?
    @add_publishers = [{}] if @add_publishers.blank?
  end

  def set_and_create_root_manifestation(params)
    # set class instance attributes
    @subject = params[:manifestation][:subject]
    @subject_transcription = params[:manifestation][:subject_transcription]
    @series_work_has_languages = WorkHasLanguage.
      create_attrs(params[:language_id].try(:values), params[:language_type].try(:values))
    if SystemConfiguration.get('manifestation.use_titles')
      titles = params[:manifestation][:work_has_titles_attributes]
      titles.each do |key, value|
        @series_statement.root_manifestation.set_title(key,params["work_has_titles_attributes_#{key}_title_str"])
       end
    end
    params[:exinfos].each { |key, value| eval("@#{key} = '#{value}'") } if params[:exinfos]
    params[:extexts].each { |key, value| eval("@#{key} = '#{value}'") } if params[:extexts]
    set_agent_instance_from_params # Implemented in application_controller.rb
    # create
    @series_statement.root_manifestation = SeriesStatement.create_root_manifestation(@series_statement,
      { subjects: @subject, subject_transcription: @subject_transcription,
        creates:  @creates,  del_creators:     @del_creators,     add_creators: @add_creators,
        realizes: @realizes, del_contributors: @del_contributors, add_contributors: @add_contributors,
        produces: @produces, del_publishers:   @del_publishers,   add_publishers: @add_publishers,
        exinfos: params[:exinfos], extexts: params[:extexts], series_work_has_languages: @series_work_has_languages })
  end
end
