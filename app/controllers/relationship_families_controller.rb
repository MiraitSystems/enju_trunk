class RelationshipFamiliesController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.relationship_family'))", 'users_path', :only => :index
  add_breadcrumb "I18n.t('page.new',     :model => I18n.t('activerecord.models.relationship_family'))", 'new_user_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.relationship_family'))", 'edit_user_path(params[:id])', :only => [:edit, :update]
  load_and_authorize_resource

  def index
    query = params[:query].to_s.strip
    @query = query.dup
    query = "#{query}*" if query.size == 1

    @relationship_families = RelationshipFamily.search do
      fulltext query if query
      paginate :page => params[:page] || 1, :per_page => RelationshipFamily.default_per_page
    end.results
  end
end
