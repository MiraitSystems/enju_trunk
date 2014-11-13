class PageController < ApplicationController
  clear_breadcrumbs :only => [:index]
  add_breadcrumb "I18n.t('breadcrumb.search_manifestations')", 'root_path', :except => [:index]
  add_breadcrumb "I18n.t('page.configuration')", 'page_configuration_path', :only => [:configuration]
  add_breadcrumb "I18n.t('page.import_from_file')", 'page_import_path', :only => [:import]
  add_breadcrumb "I18n.t('page.advanced_search')", 'page_import_path', :only => [:advanced_search]
  add_breadcrumb "I18n.t('page.statistics')", 'page_exstatistics_path', :only => [:exstatistics]
  before_filter :redirect_user, :only => :index
  before_filter :clear_search_sessions, :only => [:index, :advanced_search]
  before_filter :store_location, :only => [:advanced_search, :about, :add_on, :msie_acceralator]
  before_filter :authenticate_user!, :except => [:index, :advanced_search, :about, :add_on, :msie_acceralator, :opensearch, :routing_error, :get_manual, :show_pc_site, :show_mobile_site]
  before_filter :check_librarian, :except => [:index, :advanced_search, :about, :add_on, :msie_acceralator, :opensearch, :routing_error, :get_manual, :show_pc_site, :show_mobile_site]
  helper_method :get_libraries
  before_filter :set_no_cache_header

  def index
    @numdocs = Manifestation.search.total
    if defined?(EnjuBookmark)
      # TODO: タグ下限の設定
      #@tags = Tag.all(:limit => 50, :order => 'taggings_count DESC')
      @tags = Bookmark.tag_counts.sort{|a,b| a.count <=> b.count}.reverse[0..49]
    end
    if defined?(EnjuEvent)
      if current_user
        @events = Event.where("required_role_id <= #{current_user.role.id}").order('start_at DESC').limit(5)
      else
        @events = Event.where("required_role_id <= #{Role.where(:name => 'Guest').first.id}").order('start_at DESC').limit(5)
      end
    end
    @manifestation = Manifestation.pickup rescue nil
    get_libraries
    get_manifestation_types
    get_carrier_types

    respond_to do |format|
      if defined?(EnjuCustomize) && EnjuCustomize.method_defined?(:render_dir) && EnjuCustomize.method_defined?(:render_layout)
        format.html { render :file => "page/#{EnjuCustomize.render_dir}/index", :layout => EnjuCustomize.render_layout}
      else
        format.html
      end
      format.json { render :json => user }
    end
  end

  def msie_acceralator
    render :layout => false
  end

  def opensearch
    render :layout => false
  end

  def advanced_search
    get_series_statement
    get_libraries
    @title = t('page.advanced_search')
    # 資料区分
    get_manifestation_types
    if params[:manifestation_types].blank?
      params[:manifestation_types] = {}
      @manifestation_types.each do |manifestation_type|
        params[:manifestation_types].store(manifestation_type.id.to_s, "true")
      end
    end
    @selected_manifestation_types = params[:manifestation_types]
    @classification_types = ClassificationType.order("position").all

    if params[:classifications].blank?
      @classifications = []
      number_of_form = SystemConfiguration.get('manifestation.search.number_of_classification_field') || 3
      number_of_form.times do
        @classifications << {:classification_id => "", :classification_type_id => 2}
      end
    else
      @classifications = params[:classifications]
      @classification_mobile = params[:classifications][0][:classification_identifier]
    end
  end

  def exstatistics
    @title = t('page.ex_statistics')
  end

  def configuration
    @title = t('page.configuration')
  end

  def import
    @title = t('page.import')
  end

  def export
    @title = t('page.export')
  end

  def about
    @title = t('page.about_this_system')
  end

  def add_on
    @title = t('page.add_on')
  end

  def under_construction
    @title = t('page.under_construction')
  end

  def routing_error
    render_404
  end

  def get_manual
    access_denied unless SystemConfiguration.get('display_manual')
    if user_signed_in? && current_user.has_role?('Librarian')
      filepath = Rails.root.join('public/manual_for_librarian.pdf')
      filename = t('manual_for_librarian')
    else
      filepath = Rails.root.join('public/manual_for_user.pdf')
      filename = t('manual_for_user')
    end
    send_file filepath, :filename => filename
  end

  def show_pc_site
    session[:enju_mobile_view] = false
    session[:redirect_mode] = true
    redirect_to root_path, :status => 303
  end

  def show_mobile_site
    session[:enju_mobile_view] = true
    session[:redirect_mode] = true
    redirect_to root_path, :status => 303
  end

  private
  def set_no_cache_header
    if session[:redirect_mode]
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
      session[:redirect_mode] = nil
    end
  end

  def check_librarian
    unless current_user.has_role?('Librarian')
      access_denied
    end
  end

  def redirect_user
    if user_signed_in?
      flash.keep(:notice) if flash[:notice]
      redirect_to my_account_url
      return
    end
  end
end
