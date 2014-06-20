class TotalingReportsController < ApplicationController
  before_filter :check_librarian
  # load_and_authorize_resource

  def index
    @manifestation_types = ManifestationType.all
    if params[:manifestation_types]
      logger.error "###### params[:manifestation_types] exist ########"
      @selected_type_ids = params[:manifestation_types].map{|m| m.to_i}
      @selected_types = ManifestationType.find(:all, :conditions => ["id IN (?)", @selected_type_ids])
    else
      logger.error "###### params[:manifestation_types] NOT exist ########"
      @selected_types = @manifestation_types
      @selected_type_ids ||= @selected_types.map(&:id)
    end
    all_items = Item.joins(:manifestation)
    @shelves = Shelf.all
    @list = Array.new
    @subtotal = Array.new
    @total = 0
    @selected_types.each do |m|
      subtotal = 0
      @shelves.each do |s|
        manifestation_type = m.display_name.localize
        shelf = s.display_name.localize
        @number_of_shelves = Shelf.find(:all).count
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
    all_items = Item.joins(:manifestation)
    @manifestation_types = ManifestationType.all
    @shelves = Shelf.all
    @selected_type_ids ||= @manifestation_types.map(&:id)
    @list = Array.new
    @subtotal = Array.new
    @total = 0
    @manifestation_types.each do |m|
      subtotal = 0
      @shelves.each do |s|
        manifestation_type = m.display_name.localize
        shelf = s.display_name.localize
        @number_of_shelves = Shelf.find(:all).count
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
end
