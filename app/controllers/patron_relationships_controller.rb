class PatronRelationshipsController < InheritedResources::Base
  load_and_authorize_resource
  before_filter :prepare_options, :except => [:index, :destroy]
  before_filter :parent_child_delete, :only => [:destroy]

  def parent_child_delete
    # レコード削除時、親子レコードが相互にある場合（通常発生しないが）、
    # 対象レコードのparent_idとchild_idを入れ替えて検索し、対象レコードを削除
    pr_result = PatronRelationship.find(params[:id])
    PatronRelationship.where(["parent_id = ? AND child_id = ?", pr_result.child_id, pr_result.parent_id]).destroy_all rescue nil
  end

  def prepare_options
    @patron_relationship_types = PatronRelationshipType.all
  end

  def new
    @patron_relationship = PatronRelationship.new(params[:patron_relationship])
    @patron_relationship.parent = Patron.find(params[:patron_id]) rescue nil
    @patron_relationship.child = Patron.find(params[:child_id]) rescue nil
  end

  def create
    create! {patron_patrons_path(@patron_relationship.parent, :mode => 'show')}
  end

  def update
    @patron_relationship = PatronRelationship.find(params[:id])
    if params[:position]
      @patron_relationship.insert_at(params[:position])
      redirect_to patron_relationships_url
      return
    end
    update!
  end

  def destroy
    patron_id = params[:patron_id]
    relationship_type_id = params[:patron_relationship_type]
    destroy! do |format|
      relationship_type_id = nil if PatronRelationship.count_relationship(patron_id, relationship_type_id) == 0
      format.html {redirect_to patron_patrons_path(patron_id, :mode => 'show', :patron_relationship_type => relationship_type_id)}
    end
  end
end
