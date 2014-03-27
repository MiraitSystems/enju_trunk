module OrdersHelper

  def paid_flags
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_paid_flag_key, Time.zone.now) rescue nil
  end

  def adption_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_adption_code_key, Time.zone.now) rescue nil
  end

  def deliver_place_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_deliver_place_code_key, Time.zone.now) rescue nil
  end

  def application_form_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_application_form_code_key, Time.zone.now) rescue nil
  end

  def collection_status_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_collection_status_code_key, Time.zone.now) rescue nil
  end

  def reason_for_collection_stop_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_reason_for_collection_stop_code_key, Time.zone.now) rescue nil
  end

  def order_form_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_order_form_code_key, Time.zone.now) rescue nil
  end

  def collection_form_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_collection_form_code_key, Time.zone.now) rescue nil
  end

  def payment_form_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_payment_form_code_key, Time.zone.now) rescue []
  end

  def budget_subject_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_budget_subject_code_key, Time.zone.now) rescue nil
  end

  def transportation_route_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_transportation_route_code_key, Time.zone.now) rescue nil
  end

  def bookstore_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_bookstore_code_key, Time.zone.now) rescue []
  end

  def reference_codes
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_order_reference_code_key, Time.zone.now) rescue nil
  end

  def publisher_types
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_publisher_type_key, Time.zone.now) rescue nil
  end


  def get_paid_flag
#    return Keycode.find(:conditions => ["name = ? AND v = ? AND (ended_at < ? OR ended_at IS NULL)",use_paid_flag_key, '1', Time.zone.now]) rescue nil

    return Keycode.where("name = ? AND v = ? AND(ended_at < ? OR ended_at IS NULL)", use_paid_flag_key, '1', Time.zone.now).first rescue nil

  end












end

