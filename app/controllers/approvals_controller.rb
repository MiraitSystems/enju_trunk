class ApprovalsController < ApplicationController
  authorize_function
  load_and_authorize_resource

  def initialize
    @selected_status, @selected_approval_result = [], []
    @ouput_columns = Approval.ouput_columns
    super
  end

  def index
    # all checked
    @check_all_status = true
    @check_all_approval_result = true
    statuses = t('activerecord.attributes.approval.approval_status')
    @selected_status = statuses.present? ? statuses.collect{|k,v| k.to_s} : []
    @selected_status << "notset" #未設定
    approval_results = self.class.helpers.select_approval_result
    @selected_approval_result = approval_results.present? ? approval_results.collect{|i| i.v} : []
    @selected_approval_result << "notset" #未設定

    @approvals = Approval.page(params[:page])

  end

  def new
    @approval = Approval.new
    @approval.manifestation_id = params[:manifestation_id]
    @approval.created_by = current_user.id
    @approval.all_process_start_at = Date.today

    @manifestation = Manifestation.find(params[:manifestation_id]) if params[:manifestation_id]

    @select_user_tags = Approval.struct_user_selects
    @select_agent_tags = Approval.struct_agent_selects

    @maxposition = 0
    @approval.approval_extexts << ApprovalExtext.new(:position => 1, :comment_at => Date.today)
  end

  def create

    @approval = Approval.new(params[:approval])
    @approval.check_status
    @approval.identifier = params[:identifier] if params[:identifier]

    respond_to do |format|
      if @approval.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.approval'))
        format.html { redirect_to @approval }
      else
        if @approval.manifestation_id
          @manifestation = Manifestation.find(@approval.manifestation_id)
        end
        @select_user_tags = Approval.struct_user_selects
        @select_agent_tags = Approval.struct_agent_selects
        @identifier = params[:identifier]
        @maxposition = 0

        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @approval = Approval.find(params[:id])

    @manifestation = Manifestation.find(@approval.manifestation_id)
    @select_user_tags = Approval.struct_user_selects
    @select_agent_tags = Approval.struct_agent_selects

    @maxposition = ApprovalExtext.maximum('position', :conditions => ["approval_id = ?", params[:id]])
    @countextexts = ApprovalExtext.count(:conditions => ["approval_id = ?", params[:id]])

    if @countextexts == 0
      @approval.approval_extexts << ApprovalExtext.new(:position => 1, :comment_at => Date.today)
      @maxposition = 0
    end

  end

  def update

    @approval = Approval.find(params[:id])

    respond_to do |format|
      if @approval.update_attributes(params[:approval])
         @approval.check_status

        format.html { redirect_to @approval, :notice => t('controller.successfully_updated', :model => t('activerecord.models.approval')) }
      else

        @manifestation = Manifestation.find(@approval.manifestation_id)
        @select_user_tags = Approval.struct_user_selects
        @select_agent_tags = Approval.struct_agent_selects

        format.html { render :action => "edit" }
     end
    end
  end

  def show
    @approval = Approval.find(params[:id])
    @manifestation = Manifestation.find(@approval.manifestation_id)
  end

  def destroy
    @approval = Approval.find(params[:id])
    respond_to do |format|
      @approval.destroy
      format.html { redirect_to(approvals_url) }
    end
  end

  def get_approval_report
    begin
      @approval = Approval.find(params[:param])
      case params[:output]
      when 'report'
        file = ReportExport.get_approval_report_pdf(@approval)
        send_data file.generate, :filename => Setting.approval.report_pdf.filename, :type => 'application/pdf', :disposition => 'attachment'
      when 'postcard'
        file = ReportExport.get_approval_postcard_pdf(@approval)
        send_data file.generate, :filename => Setting.approval.postcard_pdf.filename, :type => 'application/pdf', :disposition => 'attachment'
      when 'request', 'refuse'
        if params[:output] == 'request'
          file_type = 'sample_request'
          file_name = Setting.approval.request_txt.filename
        end
        if params[:output] == 'refuse'
          file_type = 'refusal_letter' 
          file_name = Setting.approval.refuse_txt.filename
        end
        file = ReportExport.get_approval_donation_txt(@approval, file_type)
        send_data file, :filename => file_name
      when 'usually', 'sample', 'collection'
        file_type = 'donation_request_' + params[:output] 
        logger.info(file_name)
        file_name = Setting.approval.usually_txt.filename if params[:output] == 'usually'
        logger.info(file_name)
        file_name = Setting.approval.sample_txt.filename if params[:output] == 'sample'
        logger.info(file_name)
        file_name = Setting.approval.collection_txt.filename if params[:output] == 'collection'
        logger.info(file_name)
        file = ReportExport.get_approval_donation_txt(@approval, file_type)
        send_data file, :filename => file_name
      when /\_cover$/
        file_type = params[:output]
        file_name = Setting.approval.request_cover_txt.filename if params[:output] == 'request_cover'
        file_name = Setting.approval.usually_cover_txt.filename if params[:output] == 'usually_cover'
        file_name = Setting.approval.sample_cover_txt.filename if params[:output] == 'sample_cover'
        file_name = Setting.approval.collection_cover_txt.filename if params[:output] == 'collection_cover'
        file_name = Setting.approval.refuse_cover_txt.filename if params[:output] == 'refuse_cover'
        file = ReportExport.get_approval_cover_txt(@approval, file_type)
        send_data file, :filename => file_name
      else
        flash[:error] = I18n.t('page.error_file')
        redirect_to :back
      end
    rescue Exception => e
      flash[:error] = I18n.t('page.error_file')
      logger.error e
      redirect_to :back
    end
  end

  # GET /approvals/search
  def search

    @approvals = Approval.scoped

    # approval_identifier
    unless params[:approval_identifier].blank?
      @approvals = @approvals.where(["approvals.approval_identifier like ?", params[:approval_identifier] + "%"])
    end

    # identifier
    unless params[:identifier].blank?
      @approvals = @approvals.where(["manifestations.identifier like ?", params[:identifier] + "%"])
    end

    # status
    unless params[:status].blank?
      if params[:status].include?("notset")
        ids = params[:status].reject{|e| e == "notset"}
        if ids.blank?
          @approvals = @approvals.where("status IS NULL")
        else
          @approvals = @approvals.where(["status in (?) OR status IS NULL", ids])
        end
      else
        @approvals = @approvals.where(["status in (?)", params[:status]])
      end
    end

    # approval_result
    unless params[:approval_result].blank?
      if params[:approval_result].include?("notset")
        ids = params[:approval_result].reject{|e| e == "notset"}
        if ids.blank?
          @approvals = @approvals.where("approval_result IS NULL")
        else
          @approvals = @approvals.where(["approval_result in (?) OR approval_result IS NULL", ids])
        end
      else
        @approvals = @approvals.where(["approval_result in (?)", params[:approval_result]])
      end
    end

    @approvals = @approvals.joins(:manifestation).page(params[:page])

    @check_all_status = params[:check_all_status]
    @check_all_approval_result = params[:check_all_approval_result]
    @selected_status = params[:status] if params[:status].present?
    @selected_approval_result = params[:approval_result] if params[:approval_result].present? 
    @selected_approval_identifier = params[:approval_identifier]
    @selected_identifier = params[:identifier]
    
    respond_to do |format|
      format.html {render "index"}
    end
  end

  # POST /approvals/output_csv
  def output_csv
    approvals = Approval.scoped
    # approval_identifier
    unless params[:approval_identifier].blank?
      approvals = approvals.where(["approvals.approval_identifier like ?", params[:approval_identifier] + "%"])
    end

    # identifier
    unless params[:identifier].blank?
      approvals = approvals.where(["manifestations.identifier like ?", params[:identifier] + "%"])
    end

    # status
    unless params[:status].blank?
      if params[:status].include?("notset")
        ids = params[:status].reject{|e| e == "notset"}
        if ids.blank?
          approvals = approvals.where("status IS NULL")
        else
          approvals = approvals.where(["status in (?) OR status IS NULL", ids])
        end
      else
        approvals = approvals.where(["status in (?)", params[:status]])
      end
    end

    # approval_result
    unless params[:approval_result].blank?
      if params[:approval_result].include?("notset")
        ids = params[:approval_result].reject{|e| e == "notset"}
        if ids.blank?
          approvals = approvals.where("approval_result IS NULL")
        else
          approvals = approvals.where(["approval_result in (?) OR approval_result IS NULL", ids])
        end
      else
        approvals = approvals.where(["approval_result in (?)", params[:approval_result]])
      end
    end

    approvals = approvals.includes(:manifestation)
    
    data = CSV.generate(:force_quotes => true) do |csv|
      if params[:ouput_column].present?
        # ヘッダー
        header = []
        params[:ouput_column].each do |name|
          name_ja = t("approval_output_csv.#{name}")
          header << name_ja
        end
        csv << header
        # 明細
        approvals.each.with_index(1) do |approval, index|
          detail = []
          params[:ouput_column].each do |name|
            case name
              when "approval_identifier"
                detail << approval.approval_identifier
              when "four_priority_areas"
                detail << (approval.four_priority_areas_code.present? ? approval.four_priority_areas_code.keyname : "")
              when "document_classification_1"
                detail << (approval.document_classification_1_code.present? ? approval.document_classification_1_code.keyname : "")
              when "document_classification_2"
                detail << (approval.document_classification_2_code.present? ? approval.document_classification_2_code.keyname : "")
              when "sample_note"
                detail << approval.sample_note
              when "group_approval_result"
                detail << self.class.helpers.get_keyname_group_approval_result(approval.group_approval_result.to_s)
              when "group_result_reason"
                detail << self.class.helpers.get_keyname_group_result_reason(approval.group_result_reason.to_s)
              when "group_note"
                detail << approval.group_note
              when "adoption_report_flg"
                detail << approval.adoption_report_flg
              when "approval_result"
                detail << self.class.helpers.get_keyname_approval_result(approval.approval_result.to_s)
              when "reason"
                detail << self.class.helpers.get_keyname_reason(approval.reason.to_s)
              when "approval_end_at"
                detail << (approval.approval_end_at.present? ?  l(approval.approval_end_at, :format => "%Y-%m-%d") : "")
              when "all_process_end_at"
                detail << (approval.all_process_end_at.present? ?  l(approval.all_process_end_at, :format => "%Y-%m-%d") : "")
              when "thrsis_review_flg"
                detail << (approval.thrsis_review_flg_code.present? ? approval.thrsis_review_flg_code.keyname : "")
              when "ja_text_author_summary_flg"
                detail << (approval.ja_text_author_summary_flg_code.present? ? approval.ja_text_author_summary_flg_code.keyname : "")
              when "en_text_author_summary_flg"
                detail << (approval.en_text_author_summary_flg_code.present? ? approval.en_text_author_summary_flg_code.keyname : "")
              when "proceedings_number_of_year"
                detail << approval.proceedings_number_of_year
              when "excepting_number_of_year"
                detail << approval.excepting_number_of_year
              when "identifier"
                detail << approval.manifestation.identifier
              when "original_title"
                detail << approval.manifestation.original_title
              when "carrier_type"
                detail << (approval.manifestation.carrier_type.present? ? approval.manifestation.carrier_type.display_name.localize : "")
              when "publishers"
                if approval.manifestation.publishers.present?
                  publisher_names = approval.manifestation.publishers.pluck(:full_name)
                  detail << publisher_names.join(",")
                else
                  detail << ""
                end
              when "creators"
                if approval.manifestation.creators.present?
                  creator_names = approval.manifestation.creators.pluck(:full_name)
                  detail << creator_names.join(",")
                else
                  detail << ""
                end
              when "country_of_publication"
                detail << (approval.manifestation.country_of_publication.present? ? approval.manifestation.country_of_publication.display_name : "")
              when "frequency"
                detail << (approval.manifestation.frequency.present? ? approval.manifestation.frequency.display_name : "")
              when "subject"
                if approval.manifestation.subjects.present?
                  subjects = approval.manifestation.subjects.pluck(:term)
                  detail << subjects.join(",")
                else
                  detail << ""
                end
              when "language"
                if approval.manifestation.languages.present?
                  language_type = LanguageType.where("name = 'body'").first
                  work_has_languages = approval.manifestation.work_has_languages.where(["language_type_id = ?", language_type])
                  if work_has_languages.present?
                    languages = Language.where(["id in (?)", work_has_languages.pluck(:language_id)])
                    jp_languages = languages.collect{|i| i.display_name.localize}
                    detail << jp_languages.join(",")
                  else
                    detail << ""
                  end
                else
                  detail << ""
                end
              when "date_of_publication"
                detail << (approval.manifestation.date_of_publication.present? ?  l(approval.manifestation.date_of_publication, :format => "%Y-%m-%d") : "")
              when "jmas"
                identifier_type = IdentifierType.where("name = 'jma'").first
                identifiers = Identifier.where(["identifier_type_id = ? and manifestation_id = ?", identifier_type, approval.manifestation])
                if identifiers.present?
                  detail << identifiers.first.body
                else
                  detail << ""
                end
              when "issn"
                identifier_type = IdentifierType.where("name = 'issn'").first
                identifiers = Identifier.where(["identifier_type_id = ? and manifestation_id = ?", identifier_type, approval.manifestation])
                if identifiers.present?
                  detail << identifiers.first.body
                else
                  detail << ""
                end
              when "adption_code"
                if approval.manifestation.orders.present?
                  order = approval.manifestation.orders.order("ordered_at DESC").first
                  if order.adption.present?
                    detail << order.adption.keyname
                  else
                    detail << ""
                  end
                else
                  detail << ""
                end
              when "jstage"
                detail << ""
            end
          end
          csv << detail
        end
      end
    end

    data = data.encode(Encoding::SJIS)
    send_data(data, type: 'text/csv', filename: "approvals_list_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv")
  end

end
