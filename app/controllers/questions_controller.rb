# -*- encoding: utf-8 -*-
class QuestionsController < ApplicationController
  before_filter :store_location, :only => [:index, :show, :new, :edit]
  load_and_authorize_resource
  before_filter :get_user, :except => [:edit]
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  if !SystemConfiguration.get("user_show_questions") and !current_user.has_role?('Librarian')
    before_filter :check_librarian
  end

  # GET /questions
  # GET /questions.json
  def index
    store_location
    if @user and user_signed_in?
      user = @user
    end
    c_user = current_user

    session[:params] = {} unless session[:params]
    session[:params][:question] = params

    @count = {}
    case params[:sort_by]
    when 'updated_at'
      sort_by = 'updated_at'
    when 'created_at'
      sort_by = 'created_at'
    when 'answers_count'
      sort_by = 'answers_count'
    else
      sort_by = 'updated_at'
    end

    case params[:solved]
    when 'true'
      solved = true
      @solved = solved.to_s
    when 'false'
      solved = false
      @solved = solved.to_s
    end

    search = Sunspot.new_search(Question)
    query = params[:query].to_s.strip
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      search.build do
        fulltext query
      end
    end
    search.build do
      order_by sort_by, :desc
    end

    search.build do
      with(:username).equal_to user.username if user
      if c_user != user
        unless c_user.has_role?('Librarian')
          with(:shared).equal_to true
        end
      end
      facet :solved
    end

    @question_facet = search.execute!.facet(:solved).rows

    if @solved
      search.build do
        with(:solved).equal_to solved
      end
    end
    
    page = params[:page] || 1
    
    search.query.paginate(page.to_i, Question.default_per_page)
    result = search.execute!
    @questions = result.results
    @count[:query_result] = @questions.total_entries

    if query.present?
      begin
        @crd_results = Question.search_crd(:query_01 => query, :page => params[:crd_page])
      rescue Timeout::Error
        @crd_results = WillPaginate::Collection.create(1,1,0) do end
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        if params[:mode] == 'crd'
          render :template => 'questions/index_crd'
          convert_charset
        else
          render :xml => @questions
        end
      }
      format.rss  { render :layout => false }
      format.atom
      format.js
    end
  end

  # GET /questions/1
  # GET /questions/1.json
  def show
    if @user
      @question = @user.questions.find(params[:id])
    else
      @question = Question.find(params[:id])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json {
        if params[:mode] == 'crd'
          render :template => 'questions/show_crd'
          convert_charset
        else
          render :xml => @question
        end
      }
    end
  end

  # GET /questions/new
  def new
    @question = current_user.questions.new
  end

  # GET /questions/1/edit
  def edit
    if @user
      @question = @user.questions.find(params[:id])
    else
      @question = Question.find(params[:id])
    end
  end

  # POST /questions
  # POST /questions.json
  def create
    @question = current_user.questions.new(params[:question])

    respond_to do |format|
      if @question.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.question'))
        format.html { redirect_to @question }
        format.json { render :json => @question, :status => :created, :location => user_question_url(@question.user, @question) }
      else
        format.html { render :action => "new" }
        format.json { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.json
  def update
#    @question = @user.questions.find(params[:id]) 
    @question = Question.find(params[:id])
    respond_to do |format|
      if @question.update_attributes(params[:question])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.question'))
        format.html { redirect_to @question }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    if @user
      @question = @user.questions.find(params[:id])
    else
      @question = Question.find(params[:id])
    end
    @question.destroy

    respond_to do |format|
      format.html { redirect_to questions_url() }
      format.json { head :no_content }
    end
  end
end
