class ApprovalsController < ApplicationController
  authorize_function
  load_and_authorize_resource

  def index
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
    
    respond_to do |format|
      if @approval.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.approval'))
        format.html { redirect_to @approval }
      else
        @manifestation = Manifestation.find(@approval.manifestation_id)
        @select_user_tags = Approval.struct_user_selects
        @select_agent_tags = Approval.struct_agent_selects

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

        format.html { redirect_to(@approval) }
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
        #TODO ファイル名の変更箇所　:filename => ここにファイル名
        send_data file.generate, :filename => "approval_report", :type => 'application/pdf', :disposition => 'attachment'
      when 'postcard'
        file = ReportExport.get_approval_postcard_pdf(@approval)
        #TODO ファイル名の変更箇所　:filename => ここにファイル名
        send_data file.generate, :filename => "approval_postcard", :type => 'application/pdf', :disposition => 'attachment'
      when 'request', 'refuse'
        #TODO ファイル名の変更箇所　:filename => ここにファイル名
        file_name = 'sample_request' if params[:output] == 'request'
        file_name = 'refusal_letter' if params[:output] == 'refuse'
        file = ReportExport.get_approval_donation_txt(@approval, file_name)
        send_data file, :filename => file_name + '.txt'
      when 'usually', 'sample', 'collection'
        #TODO ファイル名の変更箇所　:filename => ここにファイル名
        file_name = 'donation_request_' + params[:output] 
        file = ReportExport.get_approval_donation_txt(@approval, file_name)
        send_data file, :filename => file_name + '.txt'
      when /\_cover$/
        #TODO ファイル名の変更箇所　:filename => ここにファイル名
        file_name = params[:output]
        file = ReportExport.get_approval_cover_txt(@approval, file_name)
        send_data file, :filename => file_name + '.txt'
      else
        flash[:error] = I18n.t('page.error_file')
        redirect_to :back
      end
    rescue Exception => e
      flash[:error] = I18n.t('page.error_file')
      redirect_to :back
    end
  end

end
