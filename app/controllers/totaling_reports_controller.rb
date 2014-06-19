class TotalingReportsController < ApplicationController
  # before_filter :check_librarian
  # load_and_authorize_resource

  def index
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

    @manifestation_types = ManifestationType.all
    @manifestation_separete_ids = Array.new
    @manifestation_types.each do |m|
      manifestation_separete_item_id = Manifestation.find(:all, :conditions => { :manifestation_type_id => m.id }, :select => "item_id")
      @manifestation_separete_ids << manifestation_separete_item_id
    end
    @shelves = Shelf.all
    @number_of_books = Array.new
    @shelves.each do |s|
      @manifestation_separete_ids.each do |ms_item_id|
        number_of_book = Item.count_by_sql(["SELECT count(*) FROM items WHERE shelf_id = '?' AND id = '?'", s.id, ms_item_id])
        @number_of_books << number_of_book
      end
    end
  end
end
