# TODO: NACSIS-CATからのインポートに未対応
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
    @series_statement    = SeriesStatement.find(params[:series_statement_relationship][:series_statement_id])
    @relationship_family = RelationshipFamily.find(params[:series_statement_relationship][:relationship_family_id])

    @series_statement_relationship = SeriesStatementRelationship.new(params[:series_statement_relationship])
    SeriesStatementRelationship.transaction do  
      @series_statement_relationship.save!
      # シリーズとの関連を設定
      @series_statement.relationship_family = @relationship_family
      if params[:series_statement_relationship][:before_series_statement_relationship_id]
        before_series_statement = SeriesStatement.find(params[:series_statement_relationship][:before_series_statement_relationship_id])
        before_series_statement.relationship_family = @relationship_family
      end
      if params[:series_statement_relationship][:after_series_statement_relationship_id]
        after_series_statement = SeriesStatement.find(params[:series_statement_relationship][:after_series_statement_relationship_id])
        after_series_statement.relationship_family = @relationship_family
      end
      redirect_to @series_statement_relationship
    end
  rescue Exception => e
    prepare_options
    render :action => :new
  end

  def edit
    prepare_options
    @series_statement    = @series_statement_relationship.series_statement
    @relationship_family = @series_statement_relationship.relationship_family
  end

  def update
    @relationship_family = @series_statement_relationship.relationship_family#RelationshipFamily.find(@series_statement_relationship.relationship_family_id)
    SeriesStatementRelationship.transaction do  
      present_relationship_series_statement_ids = @series_statement_relationship.relationship_family.series_statement_relationships.inject([]){ |ids, obj|
        ids << obj.before_series_statement_relationship_id unless obj.before_series_statement_relationship_id.nil? 
        ids << obj.after_series_statement_relationship_id unless obj.after_series_statement_relationship_id.nil?
      }
      @series_statement_relationship.update_attributes!(params[:series_statement_relationship])
      updated_relationship_series_statement_ids = @series_statement_relationship.relationship_family.series_statement_relationships.inject([]){ |ids, obj| 
        ids << obj.before_series_statement_relationship_id unless obj.before_series_statement_relationship_id.nil? 
        ids << obj.after_series_statement_relationship_id unless obj.after_series_statement_relationship_id.nil?
      }
      # 前誌、後誌の関連を設定
      if params[:series_statement_relationship][:before_series_statement_relationship_id].present?
        unless relationship_series_statement_ids.include?(params[:series_statement_relationship][:before_series_statement_relationship_id])
          before_series_statement = SeriesStatement.find(params[:series_statement_relationship][:before_series_statement_relationship_id])
          before_series_statement.relationship_family = @relationship_family
        end
      end
      if params[:series_statement_relationship][:after_series_statement_relationship_id].present?
        after_series_statement = SeriesStatement.find(params[:series_statement_relationship][:after_series_statement_relationship_id])
        after_series_statement.relationship_family = @relationship_family
        after_series_statement.save
      end
      # 関連がなくなったシリーズへの処理
logger.info "__________________________________________________________________________________"
logger.info present_relationship_series_statement_ids - updated_relationship_series_statement_ids
      (present_relationship_series_statement_ids - updated_relationship_series_statement_ids).each do |id|
        series_statement_delete_relationship = SeriesStatement.find(id)
        series_statement_delete_relationship.relationship_family = nil
      end 
    end
    redirect_to @series_statement_relationship
  rescue
    @series_statement = @series_statement_relationship.series_statement
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
