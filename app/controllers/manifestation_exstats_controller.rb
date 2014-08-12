class ManifestationExstatsController < ApplicationController
  add_breadcrumb "I18n.t('page.best_reader')", 'manifestation_exstats_bestreader_path', :only => [:bestreaser]
  add_breadcrumb "I18n.t('page.best_request')", 'manifestation_exstats_bestrequest_path', :only => [:bestrequest]

  def initialize
    @limit = 20
    @offset = 0
    @start_d = (Time.zone.now - 30.days).to_s[0..9]
    @end_d = Time.zone.now.to_s[0..9]
    @select_librarlies = Library.find(:all).collect{|i| [ i.display_name, i.id ] }
    @rank = 1
    @ranks = []
    @Rank = Struct.new(:rank, :manifestation, :item)
#    @selected_library = nil
    super
  end

  def bestreader
    if params[:opac] and params[:search_date_first].blank? and params[:search_date_last].blank?
      @start_d = (Date.today - 2.weeks).to_s
      @end_d = Date.today.to_s
    end
    if params[:search_date_first] || params[:search_date_last]
      @start_d = params[:search_date_first]
      @end_d = params[:search_date_last]
      @selected_library = params[:library][:id] if params[:library]
    end
    flash[:message] = ApplicationController.helpers.term_check(@start_d, @end_d)
    unless flash[:message].blank?
      render :template => 'opac/manifestation_exstats/bestreader', :layout => 'opac' if params[:opac]
      return
    end

 
    i = 0
    @checkouts = []
    while @rank <= @limit
      if @selected_library.nil? || @selected_library.empty?
        @checkout_parts = Checkout.find_by_sql(["SELECT item_id, 
          COUNT(*) AS cnt FROM checkouts LEFT OUTER 
          JOIN items on (items.id = checkouts.item_id) 
          WHERE (checkouts.created_at >= ? and checkouts.created_at < ?) 
          GROUP BY checkouts.item_id
          ORDER BY cnt DESC LIMIT ? OFFSET ?", @start_d, @end_d.to_time + 1.days, @limit, @offset]);
      else
        @checkout_parts = Checkout.find_by_sql(["SELECT item_id, 
          COUNT(*) AS cnt FROM users, checkouts LEFT OUTER 
          JOIN items on (items.id = checkouts.item_id) 
          WHERE checkouts.user_id = users.id AND users.library_id = ? AND (checkouts.created_at >= ? and checkouts.created_at < ?) 
          GROUP BY checkouts.item_id 
          ORDER BY cnt DESC LIMIT ? OFFSET ?", @selected_library, @start_d, @end_d.to_time + 1.days, @limit, @offset]);
      end
      break if @checkout_parts.length == 0

      @checkout_parts.each do |c|
        @checkouts << c
      end

      while i < @checkouts.length
        @rank = i + 1 unless @checkouts[i].cnt == @checkouts[i-1].cnt
        @item = Item.where(:id => @checkouts[i].item_id).try(:first)
        @manifestation = @item.try(:manifestation)
        @ranks << @Rank.new(@rank, @manifestation, @item) if @rank <= @limit
        i += 1
      end
      @offset += @limit
    end
    if params[:opac]
      format.html {render :template => 'opac/manifestation_exstats/bestreader', :layout => 'opac' if params[:opac]}
    elsif params[:output]
      filepath, opts = get_result_list(:bestreader_list, @ranks, @checkouts)
      send_opts = {
        :filename => opts[:filename],
        :type => opts[:mime_type] || 'application/octet-stream',
      }
      send_file filepath, send_opts   
    end
  end

  def bestrequest
    logger.info "bestrequest start"
    if params[:opac] and params[:search_date_first].blank? and params[:search_date_last].blank?
      @start_d = (Date.today - 2.weeks).to_s
      @end_d = Date.today.to_s
    end
      
    if params[:search_date_first] && params[:search_date_last]
      @start_d = params[:search_date_first]
      @end_d = params[:search_date_last]
      @selected_library = params[:library][:id] if params[:library]
    end
    flash[:message] = ApplicationController.helpers.term_check(@start_d, @end_d)
    unless flash[:message].blank?
      render :template => 'opac/manifestation_exstats/bestrequest', :layout => 'opac' if params[:opac]
      return
    end

    i = 0
    @reserves = []
    while @rank <= @limit
      if @selected_library.nil? || @selected_library.empty?
        @reserve_parts = Reserve.find(:all, :select=>'manifestation_id, COUNT(*) AS cnt', :limit=>@limit, :offset =>@offset,
          :conditions => ['reserves.created_at >= ? AND reserves.created_at < ? ',  @start_d, @end_d.to_time + 1.days], 
          :group=>'manifestation_id', :order=>'cnt DESC')
      else
        @reserve_parts = Reserve.find_by_sql(["SELECT reserves.manifestation_id, count(*) as cnt FROM reserves, users 
          WHERE reserves.created_at >= ? AND reserves.created_at < ? AND reserves.user_id = users.id AND users.library_id = ? 
          GROUP BY reserves.manifestation_id ORDER BY cnt DESC LIMIT ? OFFSET ?", @start_d, @end_d.to_time + 1.days, @selected_library, @limit, @offset])
      end
      break if @reserve_parts.length == 0

      @reserve_parts.each do |r|
        @reserves << r
      end

      while i < @reserves.length
        @rank = i + 1 unless @reserves[i].cnt == @reserves[i-1].cnt
        @manifestation = Manifestation.find(@reserves[i].manifestation_id)
        @ranks << @Rank.new(@rank, @manifestation) if @rank <= @limit
        i += 1
      end
      @offset += @limit
    end
    render :template => 'opac/manifestation_exstats/bestrequest', :layout => 'opac' if params[:opac]
  end

  private

  def get_result_list(list_type, ranks, checkouts)
    user_file = UserFile.new(current_user)
    excel_filepath, excel_fileinfo = user_file.create(list_type, Setting.bestreader_excelx.filename)

    begin
      require 'axlsx_hack'
      ws_cls = Axlsx::AppendOnlyWorksheet
    rescue LoadError
      require 'axlsx'
      ws_cls = Axlsx::Worksheet
    end  
    pkg = Axlsx::Package.new
    wb = pkg.workbook
    sty = wb.styles.add_style :font_name => Setting.bestreader_excelx.fontname
    sheet = ws_cls.new(wb)
    
    # header
    row = []
    row << I18n.t('page.exstatistics.ranknumber')
    row << I18n.t("activerecord.attributes.item.item_identifier")
    row << I18n.t("activerecord.attributes.item.identifier") if SystemConfiguration.get('item.use_different_identifier')
    row << I18n.t("activerecord.attributes.manifestation.original_title")
    row << I18n.t("activerecord.attributes.manifestation.creator")
    row << I18n.t("activerecord.attributes.manifestation.publisher")
    row << I18n.t("activerecord.models.classification")
    row << I18n.t('page.exstatistics.readercount')
    sheet.add_row row, :types => :string, :style => [sty]*row.size

    # result data
    ranks.each_with_index do |rank, i|
      row = []
      row << rank.rank || ''
      row << rank.item.try(:item_identifier) || ''
      row << rank.item.try(:identifier) || '' if SystemConfiguration.get('item.use_different_identifier')
      row << rank.manifestation.try(:original_title) || ''
      row << rank.manifestation.try(:creators).try(:map, &:full_name).try(:join, ',') || '' 
      row << rank.manifestation.try(:publishers).try(:map, &:full_name).try(:join, ',') || '' 
      row << rank.manifestation.try(:classifications).try(:map, &:category).try(:join, ',') || ''
      row << checkouts[i].cnt
      sheet.add_row row, :types => :string, :style => [sty]*row.size
    end  
    pkg.serialize(excel_filepath)
    [excel_filepath, excel_fileinfo] 
  end 
end
