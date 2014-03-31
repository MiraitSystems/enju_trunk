class SystemMaintenanceController < ApplicationController
  before_filter :check_admin

  def index
  end

  def execute
    if params['execute_exception']
      raise
    end
  end
end
