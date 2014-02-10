# coding: utf-8
class SetFunctionClassToUser
  def self.update
    con = ActiveRecord::Base.connection
    sql = "update users set function_class_id=? where id in (?)"
    con.execute(ActiveRecord::Base.send(:sanitize_sql_array, [sql, FunctionClass.find_by_name('admin').id, UserHasRole.where(:role_id => Role.find_by_name('Administrator')).collect(&:id)]))
    con.execute(ActiveRecord::Base.send(:sanitize_sql_array, [sql, FunctionClass.find_by_name('librarian').id, UserHasRole.where(:role_id => Role.find_by_name('Librarian')).collect(&:id)]))
    con.execute(ActiveRecord::Base.send(:sanitize_sql_array, [sql, FunctionClass.find_by_name('user').id, UserHasRole.where(:role_id => Role.find_by_name('User')).collect(&:id)]))
    con.execute(ActiveRecord::Base.send(:sanitize_sql_array, [sql, FunctionClass.find_by_name('user').id, UserHasRole.where(:role_id => Role.find_by_name('Guest')).collect(&:id)]))
    con.close
  end
end
