require EnjuTrunkCirculation::Engine.root.join('app', 'models', 'checkout')
class Checkout < ActiveRecord::Base
    attr_accessible :librarian_id, :item_id, :basket_id, :due_date, :created_at

    def user_group_has_checkout_type
      UserGroupHasCheckoutType.where(user_group_id: user.user_group_id, checkout_type_id: item.checkout_type_id).first
    end

    def days_overdue
      pp user_group_has_checkout_type
      number_of_delay = user_group_has_checkout_type.days_overdue
      due_date = self.due_date.localtime.to_date
      diff = Date.today - (due_date + number_of_delay.days)
      diff_i = diff.to_i
      if diff_i < 0
        diff_i = 0
      end
      return diff_i
    end
end
