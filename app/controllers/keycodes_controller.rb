class KeycodesController < ApplicationController

  def index
    @keycodes = Keycode.page(params[:page])
  end

  def new
    @keycode = Keycode.new
  end

  def create
    @keycode = Keycode.new(params[:keycode])
    respond_to do |format|
      if @keycode.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.keycode'))
        format.html { redirect_to(@keycode) }
        format.json { render :json => @keycode, :status => :created, :location => @keycode }
      else
        format.html { render :action => "new" }
        format.json { render :json => @keycode.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @keycode = Keycode.find(params[:id])
  end

  def update
    @keycode = Keycode.find(params[:id])
    respond_to do |format|
      if @keycode.update_attributes(params[:keycode])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.keycode'))
        format.html { redirect_to(@keycode) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @keycode.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @keycode = Keycode.find(params[:id])
  end

  def destroy
    @keycode = Keycode.find(params[:id])
    respond_to do |format|
      @keycode.destroy
      format.html { redirect_to(keycodes_url) }
      format.json { head :no_content }
    end
  end
end
