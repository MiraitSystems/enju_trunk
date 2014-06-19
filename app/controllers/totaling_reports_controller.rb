class TotalingReportsController < ApplicationController
  # before_filter :check_librarian
  # load_and_authorize_resource

  def index
    @selected_type_ids = params[:manifestation_types].map{|m| m.to_i} if params[:manifestation_types]
    search = Sunspot.new_search(Manifestation) #.include([:shelf => :library])
    per_page = Item.default_per_page
    page = params[:page].try(:to_i) || 1
    set_role_query(current_user, search)
    m_ids = @manifestation_type_ids
    search.build do
      with(:manifestation_type_id).any_of m_ids if m_ids
      order_by(:manifestation_type_id, :asc)
      paginate :page => page, :per_page => per_page
    end
    @manifestations = search.execute.results
    prepare_options
  end

  def prepare_options
=begin
    @manifestation_types = ManifestationType.all
    @manifestation_nums = Hash.new
    @manifestation_type_ids ||= @manifestation_types.map(&:id)
    @manifestation_types.each do |m|
      # @manifestation_nums[m.display_name.localize] = Manifestation.count_by_sql(["select count(*) from manifestations where manifestation_type_id = ?", m.id])
      @manifestation_nums[m.display_name.localize] = Manifestation.count_by_sql(["select count(*) from manifestations where manifestation_type_id = ?", m.id])
    end
=end
    all_items = Item.joins(:manifestation)
    @manifestation_types = ManifestationType.all
    @shelves = Shelf.all
    @selected_type_ids ||= @manifestation_types.map(&:id)
    @list = Array.new
    @manifestation_types.each do |m|
      @shelves.each do |s|
        manifestation_type = m.display_name.localize
        shelf = s.display_name.localize
        item_count = all_items.find(:all, :conditions => ["manifestation_type_id = ? and shelf_id = ?", m.id, s.id]).count
        @list << [manifestation_type, shelf, item_count]
      end
      # manifestation_separete_item_id = Manifestation.find(:all, :conditions => { :manifestation_type_id => m.id }, :select => "item_id")
      # @manifestation_separete_ids << manifestation_separete_item_id
    end
  end
end
