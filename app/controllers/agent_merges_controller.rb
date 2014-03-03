class AgentMergesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource
  before_filter :get_agent, :get_agent_merge_list

  # GET /agent_merges
  # GET /agent_merges.json
  def index
    if @agent
      @agent_merges = @agent.agent_merges.order('agent_merges.id').page(params[:page])
    elsif @agent_merge_list
      @agent_merges = @agent_merge_list.agent_merges.order('agent_merges.id').includes(:agent).page(params[:page])
    else
      @agent_merges = AgentMerge.page(params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @agent_merges }
    end
  end

  # GET /agent_merges/1
  # GET /agent_merges/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @agent_merge }
    end
  end

  # GET /agent_merges/new
  # GET /agent_merges/new.json
  def new
    @agent_merge = AgentMerge.new
    @agent_merge.agent = @agent

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @agent_merge }
    end
  end

  # GET /agent_merges/1/edit
  def edit
  end

  # POST /agent_merges
  # POST /agent_merges.json
  def create
    @agent_merge = AgentMerge.new(:agent_id => params[:agent_id], :agent_merge_list_id => params[:agent_merge_list_id])

    respond_to do |format|
      if @agent_merge.save
        format.json { render :json => @agent_merge, :status => :created, :location => @agent_merge }
      else
        format.json { render :json => @agent_merge.errors, :status => :unprocessable_entity }
      end
      format.html { redirect_to(agent_merge_list_agents_url(params[:agent_merge_list_id], :mode =>"add", :page => params[:page], :query => params[:query])) }
    end
  end

  # PUT /agent_merges/1
  # PUT /agent_merges/1.json
  def update
    respond_to do |format|
      if @agent_merge.update_attributes(params[:agent_merge])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.agent_merge'))
        format.html { redirect_to(@agent_merge) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @agent_merge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /agent_merges/1
  # DELETE /agent_merges/1.json
  def destroy
    AgentMerge.destroy(params[:id])
    
    respond_to do |format|
      format.html { redirect_to(agent_merge_list_agents_url(params[:agent_merge_list_id], :mode =>"add", :page => params[:page], :query => params[:query])) }
      format.json { head :no_content }
    end
  end
end
