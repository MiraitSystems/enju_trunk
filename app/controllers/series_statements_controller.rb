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

    manifestation = @manifestation
    unless params[:mode] == 'add'
      search.build do
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
    prepare_options
    original_series_statement = SeriesStatement.find(params[:series_statement_id]) if params[:series_statement_id]
    if original_series_statement
      @series_statement = original_series_statement.dup
      @series_statement.root_manifestation = original_series_statement.root_manifestation.dup
      @classifications = get_classification_values(original_series_statement.root_manifestation)
    else
      @series_statement.initialize_root_manifestation
      @classifications = get_classification_values(@series_statement.root_manifestation)
    end

    set_root_manifestation_instance_vals(@series_statement.root_manifestation)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @series_statement }
    end
  end

  # GET /series_statements/1/edit
  def edit
    @series_statement.work = @work if @work
    @creators = @series_statement.root_manifestation.try(:creates).present? ? @series_statement.root_manifestation.creates.order(:position) : [{}] unless @creators
    @contributors = @series_statement.root_manifestation.try(:realizes).present? ? @series_statement.root_manifestation.realizes.order(:position) : [{}] unless @contributors
    @publishers = @series_statement.root_manifestation.try(:produces).present? ? @series_statement.root_manifestation.produces.order(:position) : [{}] unless @publishers
    @subjects = @series_statement.root_manifestation.try(:subjects).present? ? @series_statement.root_manifestation.subjects : [{}] unless @subjects
    @classifications = get_classification_values(@series_statement.root_manifestation)
    set_root_manifestation_instance_vals(@series_statement.root_manifestation)
  end

  # POST /series_statements
  # POST /series_statements.json
  def create
    SeriesStatement.transaction do
      @series_statement = SeriesStatement.new(params[:series_statement])
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
      @series_statement.root_manifestation.destroy if @series_statement.root_manifestation
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
    @creators = root_manifestation.try(:creates).present? ? root_manifestation.creates.order(:position) : [{}] unless @creators
    @contributors = root_manifestation.try(:realizes).present? ? root_manifestation.realizes.order(:position) : [{}] unless @contributors
    @publishers = root_manifestation.try(:produces).present? ? root_manifestation.produces.order(:position) : [{}] unless @publishers
    @subjects = root_manifestation.try(:subjects).present? ? root_manifestation.subjects.order(:position) : [{}] unless @subjects
  end

  def prepare_options
    @subject_types = SubjectType.all
    @carrier_types = CarrierType.all
    @sub_carrier_types = SubCarrierType.all
    @manifestation_types = ManifestationType.all#ManifestationType.series
    @frequencies = Frequency.all
    @countries = Country.all
    @languages = Language.all_cache
    @language_types = LanguageType.all
    @roles = Role.all
    @create_types = CreateType.where(display: true).select("id, name, display_name")
    @realize_types = RealizeType.where(display: true).select("id, name, display_name")
    @produce_types = ProduceType.where(display: true).select ("id, name, display_name")
    @default_language = Language.where(:iso_639_1 => @locale).first
    @numberings = Numbering.get_manifestation_numbering('series_statement')
    @title_types = TitleType.find(:all, :select => "id, display_name, name", :order => "position")
    @work_manifestation = Manifestation.new
    @work_has_titles = @series_statement.root_manifestation.work_has_titles if @series_statement.root_manifestation
    @work_has_titles = [WorkHasTitle.new] if @work_has_titles.blank?
    @work_has_languages = @series_statement.root_manifestation.work_has_languages if @series_statement.root_manifestation
    @work_has_languages = [WorkHasLanguage.new] if @work_has_languages.blank?
    @use_licenses = UseLicense.all if defined? EnjuTrunkOrder 
    @sequence_patterns = SequencePattern.all
    @publication_statuses = PublicationStatus.all
    if SystemConfiguration.get('manifestation.use_identifiers')
      @identifier_types = IdentifierType.find(:all, :select => "id, display_name, name", :order => "position") || []
      @identifiers = @series_statement.root_manifestation.identifiers rescue []
      @identifiers << Identifier.new if @identifiers.blank?
    end
    @classification_types = ClassificationType.order("position").all
  end

  def set_and_create_root_manifestation(params)
    # set class instance attributes
    @creators = params[:creators]; @contributors = params[:contributors]; @publishers = params[:publishers];@subjects = params[:subjects]
    if @series_statement.root_manifestation.nil?
      @series_statement.root_manifestation = Manifestation.new(params[:manifestation])
    else
      @series_statement.root_manifestation.assign_attributes(params[:manifestation])
    end
    @classifications = params[:classifications]
    @series_statement.root_manifestation.classifications = create_classification_values(@classifications) unless @classifications.blank?
    # create
    @series_statement.root_manifestation = SeriesStatement.create_root_manifestation(@series_statement,
      { subjects: create_subject_values(@subjects), 
        creates: create_creator_values(@creators), 
        realizes: create_contributor_values(@contributors),
        produces: create_publisher_values(@publishers),
       })
  end

  #
  # create classification vaules
  #
  def create_classification_values(add_classifications)
    return nil if add_classifications.blank?
    classifications = []
    add_classifications.each do |add_classification|
      next if add_classification[:classification_id].blank?
      classification = Classification.where(:id => add_classification[:classification_id]).first
      classifications << classification if classification.present?
    end
    return classifications
  end

  #
  # get classification vaules
  #
  def get_classification_values(manifestation)
    classifications = []
    manifestation_has_classifications = manifestation.manifestation_has_classifications.order(:position)
    if manifestation_has_classifications.present?
      manifestation_has_classifications.each do |manifestation_has_classification|
        classifications << {:classification_type_id => manifestation_has_classification.classification.classification_type_id,
                            :classification_id => manifestation_has_classification.classification_id}
      end
    else
      classifications << {}
    end
    return classifications
  end
end
