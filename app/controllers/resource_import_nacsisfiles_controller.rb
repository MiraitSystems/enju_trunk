class ResourceImportNacsisfilesController < ApplicationController
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('resource_import_nacsisfiles.new.resource_import_nacsisfile'))", 'new_resource_import_nacsisfile_path', :only => [:new, :create]
  before_filter :check_client_ip_address
  before_filter :authenticate_user!

  def new
  end

  def create
    uploaded = params['resource_import_nacsis']

    user_file = UserFile.new(current_user)
    begin
      user_file.create(:resource_import_nacsisfile, uploaded.original_filename) do |io, info|
        open(uploaded.path, 'r') do |i|
          FileUtils.copy_stream(i, io)
        end
      end
      flash[:notice] = t('resource_import_nacsisfiles.successfully_uploaded')

    rescue
      logger.warn "failed to create resource_import_nacsisfile: #{$!.message} (#{$!.class})"
      flash[:notice] = t('resource_import_nacsisfiles.upload_failed')
    end

    respond_to do |format|
      format.html do
        redirect_to new_resource_import_nacsisfile_path
      end
    end
  end
end
