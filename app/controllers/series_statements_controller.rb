# -*- encoding: utf-8 -*-
class SeriesStatementsController < ApplicationController
  add_breadcrumb "I18n.t('page.configuration')", 'page_configuration_path'
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.series_statement'))", 'series_statements_path'
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.series_statement'))", 'new_series_statement_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.series_statement'))", 'edit_series_statement_path([:id])', :only => [:edit, :update]
  add_breadcrumb "I18n.t('activerecord.models.series_statement')", 'series_statement_path([:id])', :only => [:show]
  load_and_authorize_resource
  before_filter :get_work, :only => [:index, :new, :edit]
  before_filter :get_manifestation, :only => [:index, :new, :edit]
  before_filter :prepare_options, :only => [:new, :edit]
  cache_sweeper :page_sweeper, :only => [:create, :update, :destroy]
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
    #@manifestations = @series_statement.manifestations.periodical_children.page(params[:manifestation_page]).per_page(Manifestation.default_per_page)

    respond_to do |format|
      format.html { # show.html.erb
        if user_signed_in? and current_user.has_role?('Librarian')
          redirect_to series_statement_manifestations_url(@series_statement, :all_manifestations => true)
        else
          redirect_to series_statement_manifestations_url(@series_statement)
        end
      }
      format.json { render :json => @series_statement }
      #format.js
      format.mobile {
        if user_signed_in? and current_user.has_role?('Librarian')
          redirect_to series_statement_manifestations_url(@series_statement, :all_manifestations => true)
        else
          redirect_to series_statement_manifestations_url(@series_statement)
        end
      }
    end

  end

  # GET /series_statements/new
  # GET /series_statements/new.json
  def new
    @series_statement = SeriesStatement.new
    @manifestation = @series_statement.root_manifestation
    @series_statement.root_manifestation = Manifestation.new
    output_patron_parameter_for_new_edit
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @series_statement }
    end
  end

  # GET /series_statements/1/edit
  def edit
    @series_statement.work = @work if @work
    @series_statement.root_manifestation = Manifestation.new unless @series_statement.root_manifestation
    output_patron_parameter_for_new_edit
    if @series_statement.root_manifestation
      manifestation = @series_statement.root_manifestation
      @subject = manifestation.subjects.collect(&:term).join(';')
    end
  end

  # POST /series_statements
  # POST /series_statements.json
  def create
    @series_statement = SeriesStatement.new(params[:series_statement])
    @series_statement.root_manifestation = Manifestation.new(params[:manifestation])
    SeriesStatement.transaction do
      if @series_statement.periodical
        @series_statement.root_manifestation.original_title = params[:series_statement][:original_title] if  params[:series_statement][:original_title]
        @series_statement.root_manifestation.title_transcription = params[:series_statement][:title_transcription] if params[:series_statement][:title_transcription]
        @series_statement.root_manifestation.title_alternative = params[:series_statement][:title_alternative] if params[:series_statement][:title_alternative]
        @series_statement.root_manifestation.periodical_master = true
        @subject = params[:manifestation][:subject]
        @series_statement.root_manifestation.subjects     = Subject.import_subject(@subject) unless @subject.blank?
        @series_statement.root_manifestation.save! # if @series_statement.periodical
        @series_statement.manifestations << @series_statement.root_manifestation
      end
      @series_statement.save!

      input_patron_parameter
      if @series_statement.periodical
        #patronsテーブルに無いpatronの追加
        unless SystemConfiguration.get("add_only_exist_patron")
          @new_creator = Patron.add_patrons(@new_creator_name, @new_creator_transcription).collect(&:id)
          @new_contributor = Patron.add_patrons(@new_contributor_name, @new_contributor_transcription).collect(&:id)
          @new_publisher = Patron.add_patrons(@new_publisher_name, @new_publisher_transcription).collect(&:id)
        end
        #著作関係(creates)のpatron追加
        Create.add_creates(@series_statement.root_manifestation.id, @upd_creator, @upd_creator_type, @del_creator, true)
        Create.add_creates(@series_statement.root_manifestation.id, @add_creator, @add_creator_type)
        Create.add_creates(@series_statement.root_manifestation.id, @new_creator, @new_creator_type)
        #表現関係(realizes)のpatron追加
        Realize.add_realizes(@series_statement.root_manifestation.id, @upd_contributor, @upd_contributor_type, @del_contributor, true)
        Realize.add_realizes(@series_statement.root_manifestation.id, @add_contributor, @add_contributor_type)
        Realize.add_realizes(@series_statement.root_manifestation.id, @new_contributor, @new_contributor_type)
        #出版関係(produces)のpatron追加
        Produce.add_produces(@series_statement.root_manifestation.id, @upd_publisher, @upd_publisher_type, @del_publisher, true)
        Produce.add_produces(@series_statement.root_manifestation.id, @add_publisher, @add_publisher_type)
        Produce.add_produces(@series_statement.root_manifestation.id, @new_publisher, @new_publisher_type)
      end

      respond_to do |format|
        format.html { redirect_to @series_statement,
          :notice => t('controller.successfully_created', :model => t('activerecord.models.series_statement')) }
        format.json { render :json => @series_statement, :status => :created, :location => @series_statement }
      end
    end
    rescue Exception => e
      logger.error "Failed to create: #{e}"
      prepare_options
      output_patron_parameter
      respond_to do |format|
        format.html { render :action => "new" }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
  end

  # PUT /series_statements/1
  # PUT /series_statements/1.json
  def update
    if params[:move]
      move_position(@series_statement, params[:move])
      return
    end
    @series_statement.assign_attributes(params[:series_statement])
    @series_statement.root_manifestation = @series_statement.root_manifestation if @series_statement.root_manifestation
    input_patron_parameter

    respond_to do |format|
      begin
        SeriesStatement.transaction do
          @subject = params[:manifestation][:subject]
          if params[:series_statement][:periodical].to_s == "1"
            if @series_statement.root_manifestation
              @series_statement.root_manifestation.assign_attributes(params[:manifestation])
            else
              @series_statement.root_manifestation = Manifestation.new(params[:manifestation])
              @series_statement.root_manifestation.original_title = params[:series_statement][:original_title] if params[:series_statement][:original_title]
              @series_statement.root_manifestation.title_transcription = params[:series_statement][:title_transcription] if params[:series_statement][:title_transcription]
              @series_statement.root_manifestation.title_alternative = params[:series_statement][:title_alternative] if params[:series_statement][:title_alternative]
              @series_statement.root_manifestation.periodical_master = true
            end
            #TODO update position to edit patrons without destroy
            @series_statement.root_manifestation.subjects     = Subject.import_subjects(@subject)
            @series_statement.root_manifestation.save!
            @series_statement.manifestations << @series_statement.root_manifestation unless @series_statement.manifestations.include?(@series_statement.root_manifestation)
          else
            if @series_statement.root_manifestation && @series_statement.valid?
              @series_statement.root_manifestation.destroy
              @series_statement.root_manifestation = nil
            end
            @series_statement.periodical = false
          end

          @series_statement.save!
          @series_statement.manifestations.map { |manifestation| manifestation.index } if @series_statement.manifestations

          if @series_statement.periodical
            #patronsテーブルに無いpatronの追加
            unless SystemConfiguration.get("add_only_exist_patron")
              @new_creator = Patron.add_patrons(@new_creator_name, @new_creator_transcription).collect(&:id)
              @new_contributor = Patron.add_patrons(@new_contributor_name, @new_contributor_transcription).collect(&:id)
              @new_publisher = Patron.add_patrons(@new_publisher_name, @new_publisher_transcription).collect(&:id)
            end
            #著作関係(creates)のpatron追加
            Create.add_creates(@series_statement.root_manifestation.id, @upd_creator, @upd_creator_type, @del_creator)
            Create.add_creates(@series_statement.root_manifestation.id, @add_creator, @add_creator_type)
            Create.add_creates(@series_statement.root_manifestation.id, @new_creator, @new_creator_type)
            #表現関係(realizes)のpatron追加
            Realize.add_realizes(@series_statement.root_manifestation.id, @upd_contributor, @upd_contributor_type, @del_contributor)
            Realize.add_realizes(@series_statement.root_manifestation.id, @add_contributor, @add_contributor_type)
            Realize.add_realizes(@series_statement.root_manifestation.id, @new_contributor, @new_contributor_type)
            #出版関係(produces)のpatron追加
            Produce.add_produces(@series_statement.root_manifestation.id, @upd_publisher, @upd_publisher_type, @del_publisher)
            Produce.add_produces(@series_statement.root_manifestation.id, @add_publisher, @add_publisher_type)
            Produce.add_produces(@series_statement.root_manifestation.id, @new_publisher, @new_publisher_type)
          end

          format.html { redirect_to @series_statement, :notice => t('controller.successfully_updated', :model => t('activerecord.models.series_statement')) }
          format.json { head :no_content }
        end
      rescue Exception => e
        logger.error "Failed to update: #{e}"
        @series_statement.root_manifestation = @series_statement.root_manifestation || Manifestation.new(params[:manifestation])
        prepare_options
        output_patron_parameter
        format.html { render :action => "edit" }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /series_statements/1
  # DELETE /series_statements/1.json
  def destroy
    respond_to do |format|
      begin
        SeriesStatement.transaction do
          if @series_statement.manifestations
            if @series_statement.manifestations.size == 1
               manifestation = @series_statement.manifestations.first
               if manifestation == @series_statement.root_manifestation
                 manifestation.destroy
               end
            end
          end
          @series_statement.destroy
          format.html { redirect_to series_statements_url }
          format.json { head :no_content }
        end
      rescue
        format.html { redirect_to(series_statements_path) }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def prepare_options
    @carrier_types = CarrierType.all
    @manifestation_types = ManifestationType.where(:name => ['japanese_magazine', 'foreign_magazine', 'japanese_serial_book', 'foreign_serial_book'])
    @frequencies = Frequency.all
    @countries = Country.all
    @languages = Language.all_cache
    @roles = Role.all
    @create_types = CreateType.find(:all, :select => "id, display_name")
    @realize_types = RealizeType.find(:all, :select => "id, display_name")
    @produce_types = ProduceType.find(:all, :select => "id, display_name")
  end

  def input_patron_parameter
    if SystemConfiguration.get("add_only_exist_patron")
      @add_creator = params[:add_creator][:creator_id].split(",")  #select2からデータ受取
      @add_creator_type = Array.new(@add_creator.length, params[:add_creator][:creator_type])
      @add_contributor = params[:add_contributor][:contributor_id].split(",")  #select2からデータ受取
      @add_contributor_type = Array.new(@add_contributor.length, params[:add_contributor][:contributor_type])
      @add_publisher = params[:add_publisher][:publisher_id].split(",")  #select2からデータ受取
      @add_publisher_type = Array.new(@add_publisher.length, params[:add_publisher][:publisher_type])
    else
      @new_creator_name = params[:creator_full_name].values.join(";") rescue ''
      @new_creator_transcription = params[:creator_full_name_transcription].values.join(";") rescue ''
      @new_creator = []
      @new_creator_type = params[:creator_type_id].values rescue []
      @new_contributor_name = params[:contributor_full_name].values.join(";") rescue ''
      @new_contributor_transcription = params[:contributor_full_name_transcription].values.join(";") rescue ''
      @new_contributor = []
      @new_contributor_type = params[:contributor_type_id].values rescue []
      @new_publisher_name = params[:publisher_full_name].values.join(";") rescue ''
      @new_publisher_transcription = params[:publisher_full_name_transcription].values.join(";") rescue ''
      @new_publisher = []
      @new_publisher_type = params[:publisher_type_id].values rescue []
    end
    @upd_creator = params[:upd_creator].keys rescue []
    @upd_creator_type = params[:upd_creator].values rescue []
    @del_creator = Array.new(@upd_creator.length, false)
    @del_creator = Hash[[@upd_creator, @del_creator].transpose].merge(params[:del_creator]).values rescue []
    @upd_contributor = params[:upd_contributor].keys rescue []
    @upd_contributor_type = params[:upd_contributor].values rescue []
    @del_contributor = Array.new(@upd_contributor.length, false)
    @del_contributor = Hash[[@upd_contributor, @del_contributor].transpose].merge(params[:del_contributor]).values rescue []
    @upd_publisher = params[:upd_publisher].keys rescue []
    @upd_publisher_type = params[:upd_publisher].values rescue []
    @del_publisher = Array.new(@upd_publisher.length, false)
    @del_publisher = Hash[[@upd_publisher, @del_publisher].transpose].merge(params[:del_publisher]).values rescue []
  end

  def output_patron_parameter
    @creators = @series_statement.root_manifestation.creators rescue []
    @creators_type = @upd_creator_type.collect{|r| r.to_i} rescue []
    @keep_creator = @add_creator.collect{|r| r.to_i}.join(",") rescue nil
    @keep_creator_type = @add_creator_type
    @keep_creator_del = @del_creator
    @new_creator = params[:creator_full_name].values rescue []
    @new_creator_transcription = params[:creator_full_name_transcription].values rescue []
    @new_creator_type = params[:creator_type_id].values.collect{|r| r.to_i} rescue []
    @new_creator_number = @new_creator.length

    @contributors = @series_statement.root_manifestation.contributors rescue []
    @contributors_type = @upd_contributor_type.collect{|r| r.to_i} rescue []
    @keep_contributor = @add_contributor.collect{|r| r.to_i}.join(",") rescue nil
    @keep_contributor_type = @add_contributor_type
    @keep_contributor_del = @del_contributor
    @new_contributor = params[:contributor_full_name].values rescue []
    @new_contributor_transcription = params[:contributor_full_name_transcription].values rescue []
    @new_contributor_type = params[:contributor_type_id].values.collect{|r| r.to_i} rescue []
    @new_contributor_number = @new_contributor.length

    @publishers = @series_statement.root_manifestation.publishers rescue []
    @publishers_type = @upd_publisher_type.collect{|r| r.to_i} rescue []
    @keep_publisher = @add_publisher.collect{|r| r.to_i}.join(",") rescue nil
    @keep_publisher_type = @add_publisher_type
    @keep_publisher_del = @del_publisher
    @new_publisher = params[:publisher_full_name].values rescue []
    @new_publisher_transcription = params[:publisher_full_name_transcription].values rescue []
    @new_publisher_type = params[:publisher_type_id].values.collect{|r| r.to_i} rescue []
    @new_publisher_number = @new_publisher.length
  end

  def output_patron_parameter_for_new_edit
    @creators = @series_statement.root_manifestation.creators rescue []
    @creators_type = @series_statement.root_manifestation.creates.order("position").pluck("create_type_id").collect{|c| c.to_i } rescue []
    @keep_creator = nil
    @keep_creator_type = []
    @keep_creator_del = []
    @new_creator =[""]
    @new_creator_transcription = [""]
    @new_creator_type = [""]
    @new_creator_number = @new_creator.length

    @contributors = @series_statement.root_manifestation.contributors rescue []
    @contributors_type = @series_statement.root_manifestation.realizes.order("position").pluck("realize_type_id").collect{|c| c.to_i } rescue []
    @keep_contributor = nil
    @keep_contributor_type = []
    @keep_contributor_del = []
    @new_contributor =[""]
    @new_contributor_transcription = [""]
    @new_contributor_type = [""]
    @new_contributor_number = @new_contributor.length

    @publishers = @series_statement.root_manifestation.publishers rescue []
    @publishers_type = @series_statement.root_manifestation.produces.order("position").pluck("produce_type_id").collect{|c| c.to_i } rescue []
    @keep_publisher = nil
    @keep_publisher_type = []
    @keep_publisher_del = []
    @new_publisher =[""]
    @new_publisher_transcription = [""]
    @new_publisher_type = [""]
    @new_publisher_number = @new_publisher.length
  end
end
