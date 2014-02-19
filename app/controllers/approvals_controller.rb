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
    @select_patron_tags = Approval.struct_patron_selects

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
        @select_patron_tags = Approval.struct_patron_selects

        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @approval = Approval.find(params[:id])

    @manifestation = Manifestation.find(@approval.manifestation_id)
    @select_user_tags = Approval.struct_user_selects
    @select_patron_tags = Approval.struct_patron_selects

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
        @select_patron_tags = Approval.struct_patron_selects

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

  # POST /approvals/1/get_approval_report
  def get_approval_report
    begin
      @approval = Approval.find(params[:id])
      file = ReportExport.get_approval_report_pdf(@approval)
      send_data file.generate, :filename => "approval_report", :type => 'application/pdf', :disposition => 'attachment'
    rescue Exception => e
      flash[:error] = "hogehoge"
      redirect_to :back
    end
  end

end
