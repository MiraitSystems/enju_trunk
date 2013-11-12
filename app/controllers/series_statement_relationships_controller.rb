class SeriesStatementRelationshipsController < InheritedResources::Base
  respond_to :html, :json
  has_scope :page, :default => 1
  load_and_authorize_resource

  def index
    @relationship_family =  RelationshipFamily.find(params[:relationship_family_id])
  end

  def new
    prepare_options({ 
      series_statement_id:    params[:series_statement_id], 
      relationship_family_id: params[:relationship_family_id] 
    })
  end

  def create
    @series_statement_relationship = SeriesStatementRelationship.new(params[:series_statement_relationship])
    if @series_statement_relationship.save
      redirect_to @series_statement_relationship
    else
      prepare_options({ 
        series_statement_id:    params[:series_statement_relationship][:series_statement_id], 
        relationship_family_id: params[:series_statement_relationship][:relationship_family_id] 
      })
      render :action => :new
    end
  end

  def edit
    prepare_options({ 
      series_statement_id:    @series_statement_relationship.series_statement_id, 
      relationship_family_id: @series_statement_relationship.relationship_family_id
    })
  end

  def update
    if @series_statement_relationship.update_attributes(params[:series_statement_relationship])
      redirect_to @series_statement_relationship
    else
      prepare_options({ 
        series_statement_id:    @series_statement_relationship.series_statement_id, 
        relationship_family_id: @series_statement_relationship.relationship_family_id
      })
      render :action => :edit
    end
  end

  private
  def prepare_options(attrs = {})
    @series_statement    = SeriesStatement.find(attrs[:series_statement_id])
    @relationship_family = RelationshipFamily.find(attrs[:relationship_family_id])
    @series_statement_relationship_types = SeriesStatementRelationshipType.select([:id, :display_name])
                                             .inject([]){ |types, type| types << [type.display_name, type.id] }
  end
=begin
    @series_statement_relationship.parent = SeriesStatement.find(params[:parent_id]) rescue nil
    @series_statement_relationship.child = SeriesStatement.find(params[:child_id]) rescue nil
  end

  def update
    @series_statement_relationship = SeriesStatementRelationship.find(params[:id])
    if params[:move]
  end

  private
  def prepare_options
    @series_statement_relationship_types = SeriesStatementRelationshipType.select([:typeid, :display_name])
                                             .inject([]){ |types, type| types << [type.display_name, type.typeid] }
  end
=begin
    @series_statement_relationship.parent = SeriesStatement.find(params[:parent_id]) rescue nil
    @series_statement_relationship.child = SeriesStatement.find(params[:child_id]) rescue nil
  end

  def update
    @series_statement_relationship = SeriesStatementRelationship.find(params[:id])
    if params[:move]
      move_position(@series_statement_relationship, params[:move])
      return
    end
    update!
  end
=end
end
