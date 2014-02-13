module PaymentsHelper

  def payment_types
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_payment_type_key, Time.zone.now) rescue nil
  end

end
