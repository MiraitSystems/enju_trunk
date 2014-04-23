class UpdateFunctionsApprovalActionNames < ActiveRecord::Migration
  def up
    function = Function.where("controller_name = 'ApprovalsController'").first
    if function
      function.update_attribute(:action_names, "read:index,show,search,output_csv\nupdate:new,create,edit,update,get_approval_report\ndelete:destroy\n")
    end
  end
 
  def down
    function = Function.where("controller_name = 'ApprovalsController'").first
    if function
      function.update_attribute(:action_names, "read:index,show\nupdate:new,create,edit,update,get_approval_report\ndelete:destroy\n")
    end
  end
end
