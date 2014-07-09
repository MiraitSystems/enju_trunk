# -*- encoding: utf-8 -*-
class UsersController < ApplicationController
  authorize_function
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.user'))", 'users_path', :only => [:index]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.user'))", 'new_user_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.user'))", 'edit_user_path(params[:id])', :only => [:edit, :update]
  #before_filter :reset_params_session
  load_and_authorize_resource :except => [:search_family, :get_family_info, :get_user_info, :get_user_rent, :output_password, :edit_user_number, :update_user_number, :output_user_notice, :create]
  helper_method :get_agent 
  before_filter :store_location, :only => [:index]
  before_filter :clear_search_sessions, :only => [:show]
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  #ssl_allowed :index, :show, :new, :edit, :create, :update, :destroy, :search_family, :get_family_info, :output_password

  def index
    @count = {}

    # set query
    @query = params[:query].to_s.dup
    @date_of_birth = params[:birth_date].to_s.dup
    @address = params[:address]
    query, flash[:message] = User.set_query(params[:query], params[:birth_date], params[:address])

    # set sort
    sort = User.set_sort(params[:sort_by], params[:order])

    # search
    page = params[:page] || 1
    role = current_user.try(:role) || Role.default_role
    search = User.search
    @search = search.build do
      fulltext query unless query.blank?
      with(:library).equal_to params[:library] if params[:library]
      with(:role).equal_to params[:role] if params[:role]
      with(:agent_type).equal_to params[:agent_type] if params[:agent_type]
      with(:required_role_id).less_than_or_equal_to role.id
      with(:user_status).equal_to params[:user_status] if params[:user_status]
      order_by sort[:sort_by], sort[:order]
      if params[:format] == 'html' or params[:format].nil?
        facet :library
        facet :role
        facet :agent_type
        facet :user_status
        paginate :page => page.to_i, :per_page => User.default_per_page
      else
        paginate :page => 1, :per_page => User.count
      end
    end
    @users = @search.execute!.results
    @count[:query_result] = @users.total_entries

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @users }
      format.pdf  { send_data User.output_userlist_pdf(@users).generate, :filename => Setting.user_list_print_pdf.filename }
      if SystemConfiguration.get("set_output_format_type") == false
        format.tsv  { send_data User.output_userlist_tsv(@users), :filename => Setting.user_list_print_tsv.filename + ".csv" }
      else
        format.tsv  { send_data User.output_userlist_tsv(@users), :filename => Setting.user_list_print_tsv.filename + ".tsv" }
      end
    end
  end

  def show
    unless @user == current_user or current_user.has_role?('Librarian')
      access_denied; return
    end 
    session[:user_return_to] = nil
    unless @user.agent
      redirect_to new_user_agent_url(@user); return
    end

    @agent = @user.agent
    family_id = FamilyUser.find(:first, :conditions => ['user_id=?', @user.id]).family_id rescue nil
    @family_users = Family.find(family_id).users.select{ |user| user != @user } if family_id

    #if defined?(EnjuBookmark)
    #  @tags = @user.bookmarks.tag_counts.sort{|a,b| a.count <=> b.count}.reverse
    #end
    #@manifestation = Manifestation.pickup(@user.keyword_list.to_s.split.sort_by{rand}.first) rescue nil

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user }
    end
  end

  def new
    if user_signed_in?
      unless current_user.has_role?('Librarian')
        access_denied; return
      end
    end
    @family_with = User.find(params[:family_user_id]) if params[:family_user_id]
    if @family_with
      @user = @family_with.dup rescue User.new
      @user.username = nil
      @user.user_number = nil
      @user.role_id = @family_with.role.id
      @agent = @family_with.agent.dup rescue Agent.new
      @agent.full_name = nil
      @agent.full_name_transcription = nil
      @family_id = FamilyUser.find(:first, :conditions => ['user_id=?',  params[:user]]).family_id rescue nil
      @agent.note_update_at = nil
      @agent.note_update_by = nil
      @agent.note_update_library = nil
      @family = @family_with.id
    else 
      @user = User.new
      @user.library = current_user.library
      @user.locale = current_user.locale
      @user.role_id = Role.where(:name => 'User').first.id
      @user.required_role_id = Role.where(:name => 'Librarian').first.id
      @agent = Agent.new
      @agent.required_role = Role.find_by_name('Librarian')
      @agent.language = Language.where(:iso_639_1 => I18n.default_locale.to_s).first || Language.first 
      @agent.country = current_user.library.country if current_user.library
      @agent.country_id = LibraryGroup.site_config.country_id
      @agent.telephone_number_1_type_id = 0
      @agent.telephone_number_2_type_id = 1
      @agent.extelephone_number_1_type_id = 2
      @agent.extelephone_number_2_type_id = 2
      @agent.fax_number_1_type_id = 3
      @agent.fax_number_2_type_id = 3
      @family = 0
    end
    #@user.openid_identifier = flash[:openid_identifier]
    prepare_options
    @user_groups = UserGroup.all
#    get_agent
#    if @agent.try(:user)
#      flash[:notice] = t('page.already_activated')
#      redirect_to @agent
#      return
#    end
    @user.agent_id = @agent.id if @agent
    logger.error "2: #{@agent.id}"
  end

  def edit
    unless @user == current_user or current_user.has_role?('Librarian')
      access_denied; return
    end 
    unless @user.agent
      redirect_to new_user_agent_url(@user); return
    end

    @user.role_id = @user.role.id
    @agent = @user.agent
    family_id = FamilyUser.find(:first, :conditions => ['user_id=?', @user.id]).family_id rescue nil
    if family_id
      @family_users = Family.find(family_id).users
    end
    #@note_last_updateed_user = User.find(@agent.note_update_by) rescue nil
    if params[:mode] == 'feed_token'
      if params[:disable] == 'true'
        @user.delete_checkout_icalendar_token
      else
        @user.reset_checkout_icalendar_token
      end
      render :partial => 'users/feed_token'
      return
    end
    prepare_options
  end

  def create
    respond_to do |format|
      begin
        Agent.transaction do
          @family = params[:family]
          @user = User.create_with_params(params[:user], params[:has_role_id])
          authorize! :create, @user
          @user.set_auto_generated_password
          @agent = Agent.create_with_user(params[:agent], @user)
 
          logger.info @agent
          logger.info @user

          @user.set_family(@family) unless @family.blank?
          @agent.save!
          @user.agent = @agent
          @user.save!
          flash[:temporary_password] = @user.password
          format.html { redirect_to @user, :notice => t('controller.successfully_created.', :model => t('activerecord.models.user')) }
          #format.html { redirect_to new_user_agent_url(@user) }
          format.json { render :json => @user, :status => :created, :location => @user }
        end
      rescue ActiveRecord::RecordInvalid
        prepare_options
        @agent.errors.each do |attr, msg|
          @user.errors.add(attr, msg)
        end 
        # flash[:error] = t('user.could_not_setup_account')
        format.html { render :action => "new" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      rescue Exception => e
        logger.error e
        logger.error $@
      end
    end
  end

  def update
    unless @user == current_user or current_user.has_role?('Librarian')
      access_denied; return
    end 
    unless @user.agent
      redirect_to new_user_agent_url(@user); return
    end

    @user = User.where(:username => params[:id]).first
    @family = params[:family]
    begin
      # set user_info
      if current_user.has_role?('Librarian')
        @user.assign_attributes(params[:user], :as => :admin)
      elsif SystemConfiguration.get('user_change_department')
        @user.assign_attributes(params[:user], :as => :user_change_department)
      else
        @user.assign_attributes(params[:user])
      end
      #@user.update_attributes!(params[:user])
      #@user.update_with_params(params[:user])
      @user.operator = current_user
      if params[:user][:auto_generated_password] == "1"
        @user.set_auto_generated_password
        flash[:temporary_password] = @user.password
      end
      if current_user.has_role?('Administrator')
        @user.role = Role.find(@user.role_id) if @user.role_id
      end

      # set agents_info
      @user.agent.update_attributes!(params[:agent])
      @user.agent.email = @user.email
      @user.agent.language = Language.find(:first, :conditions => ['iso_639_1=?', params[:user][:locale]]) rescue nil
      @user.agent.save!

      @user.out_of_family if params[:out_of_family] == "1" or @user.agent.agent_type_id != AgentType.find_by_name('Person').id
      @user.set_family(params[:family]) unless params[:family].blank?
      @user.save!

      # delete reserves when user can not check out items
      unless @user.available_for_reservation?
        @user.delete_reserves
      end

      flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.user'))
      respond_to do |format|
        format.html { redirect_to user_url(@user) }
        format.json { head :no_content }
      end
    rescue # ActiveRecord::RecordInvalid
      @agent = @user.agent  
      @agent.errors.each do |attr, msg|
        @user.errors.add(attr, msg)
      end  
      family_id = FamilyUser.find(:first, :conditions => ['user_id=?', @user.id]).family_id rescue nil
      @family_users = Family.find(family_id).users if family_id
      prepare_options
      respond_to do |format|
        format.html { render :action => "edit" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    begin
      User.transaction do
        if @user.deletable_by(current_user)
          @user.delete_reserves if @user.reserves.not_waiting
          @user.agent.destroy
          @user.destroy
        else
          flash[:notice] = @user.errors[:base].join(' ')
          redirect_to @user
          return
        end
      end
    rescue
      redirect_to @user
      return
    end

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.json { head :no_content }
    end
  end

  def edit_user_number
    if user_signed_in?
      unless current_user.has_role?('Librarian')
        access_denied; return
      end
    end
    @user = User.find_by_username(params[:id])
  end

  def update_user_number
    if user_signed_in?
      unless current_user.has_role?('Librarian')
        access_denied; return
      end
    end
    @user = User.find_by_username(params[:id])
    if params[:new_user_number].blank?
      @user.errors.add_on_blank("new_user_number")
      render :action => :edit_user_number 
      return
    end

    begin 
      @user.assign_attributes({:user_number => params[:new_user_number]}, :as => :admin)
      @user.save!
      #@user.update_attributes({:user_number => params[:new_user_number]})
      flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.attributes.user.user_number'))
      redirect_to(user_url(@user))       
    rescue # ActiveRecord::RecordInvalid
      #@user = User.find_by_username(params[:id])
      render :action => :edit_user_number 
    end
  end

  def output_password
    if user_signed_in?
      unless current_user.has_role?('Librarian')
        access_denied; return
      end
    end
    report = EnjuTrunk.new_report('password.tlf')
    report.start_new_page do |page|
      page.item(:password).value(params[:password])
    end
    send_data report.generate, :filename => "password.pdf", :type => 'application/pdf', :disposition => 'attachment'
  end

  def output_user_notice
    if user_signed_in?
      unless current_user.has_role?('Librarian')
        access_denied; return
      end
    end
    user = User.find_by_username(params[:id])
    report = EnjuTrunk.new_report('user_notice.tlf')
    report.start_new_page do |page|
      page.item(:library).value(LibraryGroup.system_name(@locale))
      page.item(:user).value(user.user_number)
      page.item(:full_name).value(user.agent.full_name)
    end
    send_data report.generate, :filename => "user_notice.pdf", :type => 'application/pdf', :disposition => 'attachment'
  end

  def search_family
    return nil unless request.xhr?
    unless params[:keys].blank?
      tel_1 = params[:keys][:tel_1]
      tel_1.delete!("-")
      @user = User.find(params[:user]) rescue nil
      @family = params[:family]
      @family_id = FamilyUser.find(:first, :conditions => ['user_id=?', @user.id]).family_id rescue nil
      agent_type_person = AgentType.find_by_name('Person').id
      query = <<-SQL
        SELECT users.id, users.username
        FROM users left join agents 
        ON agents.user_id = users.id 
        WHERE translate(agents.telephone_number_1, '-', '') = :tel_1
        AND agents.last_name = :last_name
        AND agents.address_1 = :address_1
        AND agents.agent_type_id = :agent_type_person
      SQL
      if @family.present? and @family.to_i != 0
        query += " AND users.id = :user_id"
        query_params = {:tel_1=>tel_1, :last_name=>params[:keys][:last_name], :address_1=>params[:keys][:address_1], :agent_type_person=>agent_type_person, :user_id=>@family} if @family
      else
        query += <<-SQL
          AND agents.telephone_number_1 IS NOT NULL
          AND NOT agents.telephone_number_1 = ''
          AND agents.last_name IS NOT NULL
          AND NOT agents.last_name = ''
          AND agents.address_1 IS NOT NULL
          AND NOT agents.address_1 = ''
        SQL
        query_params = {:tel_1=>tel_1, :last_name=>params[:keys][:last_name], :address_1=>params[:keys][:address_1], :agent_type_person=>agent_type_person}
      end
      @users = User.find_by_sql([query, query_params]) rescue nil
      all_user_ids = []
      if @users
        #logger.info @users
        @users.each do |user|
          #logger.info "user.id=#{user.id}"
          all_user_ids << user.id
        end 
      end
      family_users = FamilyUser.find(:all, :conditions => ['user_id IN (?)', all_user_ids]) 
      family_user_ids = []
      @families = []
      family_users.each do |f_user|
        family_user_ids << f_user.user_id
        @families << Family.find(f_user.family_id)
      end
      @families.uniq!
      already_family_users = Family.find(family_id).users if family_id rescue nil
      group_users = []
      if @families
        @families.each do |f|
          f.users.each do |u|
            group_users << u
          end
        end
      end
      @users.delete_if{|user| already_family_users.include?(user)} if already_family_users
      @users.delete_if{|user| group_users.include?(user)} if group_users
      @users.delete_if{|user| user == @user}

      #
      #logger.info("family=#{@family}")
      unless @family.empty?
        @families.each do |f|
          #logger.info enum_users_id(f.users)  
          u2 = f.users.select {|u| u.id.to_s == @family}
          unless u2.empty?
            f.users.reject! {|u| u.id.to_s == @family}
            f.users.unshift(u2.first)
            #logger.info enum_users_id(f.users)  
            break
          end
        end
      end
      unless @users.blank? && @families.blank?
        html = render_to_string :partial => "search_family"
        render :json => {:success => 1, :html => html}
      else
        render :json => {:success => false}
      end
    end
  end

  def get_family_info
    return nil unless request.xhr?
    unless params[:user_id].blank?
      family_id = FamilyUser.where(:user_id => params[:user_id]).first.family_id rescue nil
      @user = User.find(FamilyUser.where(:family_id => family_id).order(:id).first.user_id) rescue nil
      if @user.nil?
        @user = User.find(params[:user_id]) rescue nil
      end
      @agent = @user.agent
      render :json => {:success => 1, :user => @user, :agent => @agent }
    end
  end

  def get_user_info
    return nil unless request.xhr?
    unless params[:user_number].blank?
      @user = User.where(:user_number => params[:user_number]).first
      if @user
        @agent = @user.agent unless @user.blank?      
        manifestation = Manifestation.find(params[:manifestation_id])
        expired_at = manifestation.reservation_expired_period(@user).days.from_now.end_of_day
        expired_at = expired_at.try(:strftime, "%Y-%m-%d") if expired_at
      end
      render :json => {:success => 1, :user => @user, :agent => @agent, :expired_at => expired_at}
    end
  end

  def get_user_rent
    return nil unless request.xhr?
    unless params[:user_number].blank?
      user = User.where(:user_number => params[:user_number]).first
      agent = user.agent unless user.blank?
      items = user.checkouts.not_returned.inject([]){ |list, c| list << [c.item.id, c.item.manifestation.original_title ]} unless user.blank?
      render :json => { :success => 1, :items => items, :user => user, :agent => agent }
    end
  end

  private
  def enum_users_id(users)
    s = ""
    unless users.empty?
      users.each do |u|
        s.concat("#{u.id} ")
      end
    end
    return s
  end

  def prepare_options
    @user_groups = UserGroup.all
    @roles = Role.all
    @libraries = Library.all
    @languages = Language.all_cache
    @countries = Country.all_cache
    if @user.active_for_authentication?
      @user.locked = '0'
    else
      @user.locked = '1'
    end
    @agent_types = AgentType.all
    @agent_type_person = AgentType.find_by_name('Person').id
    @user_statuses = UserStatus.all
    @departments = Department.all
    @function_classes = FunctionClass.all
    @genders = Keycode.where(:name => 'agent.gender')
    @grades = Keycode.where(:name => 'agent.grade')
  end
end
