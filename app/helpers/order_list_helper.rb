module OrderListHelper
  def localized_order_state(current_state)
    case current_state
    when 'pending'
      t('state.pending')
    when 'not_ordered'
      t('order_list.not_ordered')
    when 'ordered'
      t('order_list.ordered')
    end
  end

  def accept_status(order)
    status = ""
    if order.accept
      status = "#{t('order_list.accepted')} (#{l(order.accept.created_at)})"
    end
    return status

  end
end
