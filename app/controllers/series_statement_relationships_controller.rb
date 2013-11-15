class SeriesStatementRelationshipsController < InheritedResources::Base
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.series_statement_relationship'))", 'new_series_statement_relationship_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.series_statement_relationship'))", 'series_statement_relationship_path(params[:id])',      :only => :show
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.series_statement_relationship'))", 'edit_series_statement_relationship_path(params[:id])', :only => [:edit, :update]
  respond_to :html, :json
  has_scope :page, :default => 1
  load_and_authorize_resource

  def index
    @relationship_family =  RelationshipFamily.find(params[:relationship_family_id])
  end

  def new
    prepare_options
    @series_statement    = SeriesStatement.find(params[:series_statement_id])
    @relationship_family = RelationshipFamily.find(params[:relationship_family_id])
  end

  def create
    # TODO: NACSIS-CATからのインポートに未対応
    @series_statement    = SeriesStatement.find(params[:series_statement_relationship][:series_statement_id])
    @relationship_family = RelationshipFamily.find(params[:series_statement_relationship][:relationship_family_id])

    SeriesStatementRelationship.transaction do  
      @series_statement_relationship = SeriesStatementRelationship.create!(params[:series_statement_relationship])
      @series_statement.relationship_family = @relationship_family
      if params[:series_statement_relationship][:before_series_statement_relationship_id]
        before_series_statement = SeriesStatement.find(params[:series_statement_relationship][:before_series_statement_relationship_id])
        before_series_statement.relationship_family = @relationship_family
      end
      if params[:series_statement_relationship][:after_series_statement_relationship_id]
        after_series_statement = SeriesStatement.find(params[:series_statement_relationship][:after_series_statement_relationship_id])
        after_series_statement.relationship_family = @relationship_family
      end
=begin    
    # TODO: 始端, 終端は自動設定できるようにしたい
    SeriesStatementRelationship.transaction do
      # set start relationship
      SeriesStatementRelationship.create!(params[:series_statement_relationship].merge({ 
        series_statement_relationship_type_id: 0,
        before_series_statement_relationship_id: nil,
        bbid: nil,
      }))      
      # set own relationship
      @series_statement_relationship = SeriesStatementRelationship.create!(params[:series_statement_relationship].merge({
        before_series_statement_relationship_id: @series_statement.id,
        bbid: nil#TODO
      }))
      # set end relationship
      SeriesStatementRelationship.create!(params[:series_statement_relationship].merge({ 
        series_statement_relationship_type_id: 9,
        after_series_statement_relationship_id: nil,
        abid: nil
      }))     
    end
=end
      redirect_to @series_statement_relationship
    end
  rescue 
    prepare_options
    render :action => :new
  end

  def edit
    prepare_options
    @series_statement    = SeriesStatement.find(@series_statement_relationship.series_statement_id)
    @relationship_family = RelationshipFamily.find(@series_statement_relationship.relationship_family_id)
  end

  def update
    @relationship_family = RelationshipFamily.find(@series_statement_relationship.relationship_family_id)
    SeriesStatementRelationship.transaction do  
      @series_statement_relationship.update_attributes!(params[:series_statement_relationship])

      if params[:series_statement_relationship][:before_series_statement_relationship_id]
        before_series_statement = SeriesStatement.find(params[:series_statement_relationship][:before_series_statement_relationship_id])
        before_series_statement.relationship_family = @relationship_family
# TODO: seriesの処理
#      else
#        unless @series_statement_relationship.relationship_family.series_statement_relationships.map(&:series_statement_id).include?(params[:series_statement_relationship][:before_series_statement_relationship_id])
#          before_series_statement.relationship_family = nil
#        end
      end
      if params[:series_statement_relationship][:after_series_statement_relationship_id]
        after_series_statement = SeriesStatement.find(params[:series_statement_relationship][:after_series_statement_relationship_id])
        after_series_statement.relationship_family = @relationship_family
# TODO: seriesの処理
#      else
#        unless @series_statement_relationship.relationship_family.series_statement_relationships.map(&:series_statement_id).include?(params[:series_statement_relationship][:after_series_statement_relationship_id])
#        after_series_statement.relationship_family = nil
#        end
      end
    end
    redirect_to @series_statement_relationship
  rescue
    @series_statement    = SeriesStatement.find(@series_statement_relationship.series_statement_id)
    prepare_options
    render :action => :edit
  end

  def destroy
    relationship_family = @series_statement_relationship.relationship_family
    begin
      SeriesStatementRelationship.transaction do
        @series_statement_relationship.destroy
        if relationship_family.series_statement_relationships.size > 0
          redirect_to relationship_family
        else
          series_statement = relationship_family.series_statement
          relationship_family.series_statement = nil
          series_statement.relationship_family = nil
          redirect_to series_statement
        end 
      end
    rescue
      flash[:notice] = t('series_statement_relationship.failed_destroy')
      redirect_to relationship_family
    end
  end

  private
  def prepare_options
    #TODO 始端、終端を自動登録できるようにしたい
    #@series_statement_relationship_types = SeriesStatementRelationshipType.selectable.select([:id, :display_name])
    @series_statement_relationship_types = SeriesStatementRelationshipType.select([:id, :display_name])
                                             .inject([]){ |types, type| types << [type.display_name, type.id] }
  end
end
