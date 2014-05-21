# -*- encoding: utf-8 -*-
class AgentsController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.agent'))", 'agents_path'
  add_breadcrumb "I18n.t('activerecord.models.agent')", 'agent_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.agent'))", 'new_agent_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.agent'))", 'edit_agent_path(params[:id])', :only => [:edit, :update]
  load_and_authorize_resource :except => [:index, :search_name]
  authorize_resource :only => :index
  before_filter :get_user
  helper_method :get_work, :get_expression
  helper_method :get_manifestation, :get_item
  helper_method :get_agent
  helper_method :get_agent_merge_list
  before_filter :prepare_options, :only => [:new, :edit]
  before_filter :store_location
  before_filter :get_version, :only => [:show]
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  include FormInputUtils

  # GET /agents
  # GET /agents.json
  def index
    #session[:params] = {} unless session[:params]
    #session[:params][:agent] = params
    # 最近追加されたパトロン
    #@query = params[:query] ||= "[* TO *]"
    if params[:mode] == 'add'
      unless current_user.try(:has_role?, 'Librarian')
        access_denied; return
      end
    end

    query = normalize_query_string(params[:query])
    @query = query.dup

    query = generate_adhoc_one_char_query_text(
      query, Agent, [
        :full_name, :full_name_transcription, :full_name_alternative, # name
        :place, :address_1, :address_2,
        :other_designation, :note,
      ])

    if params[:mode] == 'recent'
      query << 'created_at_d:[NOW-1MONTH TO NOW]'
    end
    logger.debug "  SOLR Query string:<#{query}>"

    order = nil
    @count = {}

    search = Sunspot.new_search(Agent)
    search.data_accessor_for(Agent).include = [
      :agent_type, :required_role
    ]
    search.data_accessor_for(Agent).select = [
      :id,
      :full_name,
      :full_name_transcription,
      :agent_type_id,
      :required_role_id,
      :created_at,
      :date_of_birth,
      :date_of_death,
      :user_id
    ]
    set_role_query(current_user, search)

    unless query.blank?
      search.build do
        fulltext query
      end
    end

    get_work; get_expression; get_manifestation; get_agent; get_agent_merge_list;
    unless params[:mode] == 'add'
      user = @user
      work = @work
      expression = @expression
      manifestation = @manifestation
      agent = @agent
      agent_merge_list = @agent_merge_list
      @agent_relationship_types = AgentRelationshipType.select("id, name, display_name")
      search.build do
        with(:user).equal_to user.username if user
        with(:work_ids).equal_to work.id if work
        with(:expression_ids).equal_to expression.id if expression
        with(:manifestation_ids).equal_to manifestation.id if manifestation
        with(:agent_merge_list_ids).equal_to agent_merge_list.id if agent_merge_list
        if agent
          param_type_id = params[:agent_relationship_type]
          param_relationship = params[:parent_child_relationship]
          if param_type_id
            case param_relationship
            when 'p'
              with(('relationship_type_parent_' + param_type_id).to_sym).equal_to agent.id
            when 'c'
              with(('relationship_type_child_' + param_type_id).to_sym).equal_to agent.id
            else
              any_of do
                with(('relationship_type_parent_' + param_type_id).to_sym).equal_to agent.id
                with(('relationship_type_child_' + param_type_id).to_sym).equal_to agent.id
              end
            end
          else
            any_of do
              with(:original_agent_ids).equal_to agent.id
              with(:derived_agent_ids).equal_to agent.id
            end
          end
        end
        AgentRelationshipType.pluck(:id).each do |type_id|
          facet 'relationship_type_parent_' + type_id.to_s
          facet 'relationship_type_child_' + type_id.to_s
        end
      end
    end

    role = current_user.try(:role) || Role.default_role
    search.build do
      with(:required_role_id).less_than role.id
      with(:user_id).equal_to(nil)
      without(:exclude_state).equal_to(1)
      order_by(:id)
      with(:agent_type).equal_to params[:agent_type] if params[:agent_type]
      facet :agent_type
    end

    page = params[:page] || 1
    search.query.paginate(page.to_i, Agent.default_per_page)
    @search = search
    @agents = search.execute!.results
    @count[:query_result] = @agents.total_entries

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @agents }
      format.rss  { render :layout => false }
      format.atom
      format.json { render :json => @agents }
      format.mobile
    end
  end

  def search_name
    struct_agent = Struct.new(:id, :text, :full_name_transcription)
    if params[:agent_id]
       a = Agent.where(id: params[:agent_id]).select("id, full_name, full_name_transcription").first
       result = nil
       result = struct_agent.new(a.id, a.full_name, a.full_name_transcription)
    else
       agents = Agent.where("full_name like '%#{params[:search_phrase]}%'").where(:user_id => nil).select("id, full_name, full_name_transcription").limit(10)
       result = []
       agents.each do |agent|
           result << struct_agent.new(agent.id, agent.full_name, agent.full_name_transcription)
       end
    end
    respond_to do |format|
      format.json { render :text => result.to_json }
    end
  end

  # GET /agents/1
  # GET /agents/1.json
  def show
    unless @agent.user.blank?
      access_denied; return
    end

    #get_work; get_expression; get_manifestation; get_item

    case
    when @work
      @agent = @work.creators.find(params[:id])
    when @manifestation
      @agent = @manifestation.publishers.find(params[:id])
    when @item
      @agent = @item.agents.find(params[:id])
    else
      if @version
        @agent = @agent.versions.find(@version).item if @version
      end
    end
    @agent_relationship_types = AgentRelationshipType.select("id, name, display_name")

    agent = @agent
    role = current_user.try(:role) || Role.default_role
    @works = Manifestation.search do
      with(:creator_ids).equal_to agent.id
      with(:required_role_id).less_than_or_equal_to role.id
      paginate :page => params[:work_list_page], :per_page => Manifestation.default_per_page
    end.results
    @expressions = Manifestation.search do
      with(:contributor_ids).equal_to agent.id
      with(:required_role_id).less_than_or_equal_to role.id
      paginate :page => params[:expression_list_page], :per_page => Manifestation.default_per_page
    end.results
    @manifestations = Manifestation.search do
      with(:publisher_ids).equal_to agent.id
      with(:required_role_id).less_than_or_equal_to role.id
      paginate :page => params[:manifestation_list_page], :per_page => Manifestation.default_per_page
    end.results

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @agent }
      format.js
      format.mobile
    end
  end

  # GET /agents/new
  # GET /agents/new.json
  def new
    unless current_user.has_role?('Librarian')
      unless current_user == @user
        access_denied; return
      end
    end
    @agent = Agent.new
    if @user
      @agent.user_username = @user.username
      @agent.required_role = Role.find_by_name('Librarian')
    else
      @agent.required_role = Role.find_by_name('Guest')
    end
    @agent.language = Language.where(:iso_639_1 => I18n.default_locale.to_s).first || Language.first
    @agent.country = current_user.library.country
    @agent.country_id = LibraryGroup.site_config.country_id
    @agent.telephone_number_1_type_id = 1
    @agent.telephone_number_2_type_id = 1
    @agent.extelephone_number_1_type_id = 2
    @agent.extelephone_number_2_type_id = 2
    @agent.fax_number_1_type_id = 3
    @agent.fax_number_2_type_id = 3
    prepare_options

    @countalias = 0
    @agent.agent_aliases << AgentAlias.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @agent }
    end
  end

  # GET /agents/1/edit
  def edit
    @countalias = AgentAlias.count(:conditions => ["agent_id = ?", params[:id]])
    if @countalias == 0
      @agent.agent_aliases << AgentAlias.new
    end
    prepare_options
  end

  # POST /agents
  # POST /agents.json
  def create
    @agent = Agent.new(params[:agent])

    if @agent.user_username
      @agent.user = User.find(@agent.user_username) rescue nil
    end
    unless current_user.has_role?('Librarian')
      if @agent.user != current_user
        access_denied; return
      end
    end

    respond_to do |format|
      if @agent.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.agent'))
        case
        when @work
          @work.creators << @agent
          format.html { redirect_to agent_work_url(@agent, @work) }
          format.json { head :created, :location => agent_work_url(@agent, @work) }
        when @expression
          @expression.contributors << @agent
          format.html { redirect_to agent_expression_url(@agent, @expression) }
          format.json { head :created, :location => agent_expression_url(@agent, @expression) }
        when @manifestation
          @manifestation.publishers << @agent
          format.html { redirect_to agent_manifestation_url(@agent, @manifestation) }
          format.json { head :created, :location => agent_manifestation_url(@agent, @manifestation) }
        when @item
          @item.agents << @agent
          format.html { redirect_to agent_item_url(@agent, @item) }
          format.json { head :created, :location => agent_manifestation_url(@agent, @manifestation) }
        else
          format.html { redirect_to(@agent) }
          format.json { render :json => @agent, :status => :created, :location => @agent }
        end
      else
        @countalias = params[:agent][:agent_aliases_attributes].size
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @agent.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /agents/1
  # PUT /agents/1.json
  def update
    respond_to do |format|
      if @agent.update_attributes(params[:agent])
        if params[:checked_item] == 'true'
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.user_note'))
          format.html { redirect_to :back }
        else
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.agent'))
          format.html { redirect_to(@agent) }
        end
        format.json { head :no_content }
      else
        @countalias = params[:agent][:agent_aliases_attributes].size
        prepare_options
        format.html { render :action => "edit" }
        format.json { render :json => @agent.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /agents/1
  # DELETE /agents/1.json
  def destroy
    @agent.destroy

    respond_to do |format|
      format.html { redirect_to agents_url, :notice => t('controller.successfully_deleted', :model => t('activerecord.models.agent')) }
      format.json { head :no_content }
    end
  end

  private
  def prepare_options
    @countries = Country.all_cache
    @agent_types = AgentType.all
    @roles = Role.all
    @languages = Language.all_cache
    @places = SubjectType.find_by_name('Place').try(:subjects)
  end
end
