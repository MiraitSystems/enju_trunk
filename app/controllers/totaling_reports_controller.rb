class TotalingReportsController < ApplicationController
  before_filter :check_librarian
  # load_and_authorize_resource

  def index
    prepare_options
    if params[:manifestation_types]
      @selected_type_ids = params[:manifestation_types].map{|m| m.to_i}
      @selected_types = ManifestationType.find(:all, :conditions => ["id IN (?)", @selected_type_ids])
    else
      @selected_types = @manifestation_types
      @selected_type_ids ||= @selected_types.map(&:id)
    end
    if params[:shelves]
      @selected_shelf_ids = params[:shelves].map{|s| s.to_i}
      @selected_shelves = Shelf.find(:all, :conditions => ["id IN (?)", @selected_shelf_ids])
    else
      @selected_shelves = @shelves
      @selected_shelf_ids ||= @selected_shelves.map(&:id)
    end
    
    all_items = Item.joins(:manifestation)
    @list = Array.new
    @subtotal = Array.new
    @total = 0
    @selected_types.each do |m|
      subtotal = 0
      @selected_shelves.each do |s|
        manifestation_type = m.display_name.localize
        shelf = s.display_name.localize
        @number_of_shelves = @selected_shelf_ids.count
        library_name = Library.find(:first, :conditions => ["id = ?", s.library_id], :select => "display_name")
        unless library_name.nil?
          library_name = library_name.display_name
        end
        item_count = all_items.find(:all, :conditions => ["manifestation_type_id = ? and shelf_id = ?", m.id, s.id]).count
        subtotal += item_count
        @total += item_count
        @list << [manifestation_type, library_name, shelf, item_count]
      end
      @subtotal << subtotal
    end
  end

  def prepare_options
    @manifestation_types = ManifestationType.all
    @shelves = Shelf.all
  end
end
