module OrderHelper
  def order_item_label(order)
    if order.item_id.present?
      return t('activerecord.models.item')
    elsif order.manifestation_id.present?
      return t('activerecord.models.manifestation')
    else
      return t('activerecord.models.purchase_request')
    end
  end
end
