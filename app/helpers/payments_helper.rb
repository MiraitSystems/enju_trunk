module PaymentsHelper

  def payment_types
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", use_payment_type_key, Time.zone.now) rescue nil
  end

  def get_keyname_payment_types(v)
    if respond_to? :use_payment_type_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", use_payment_type_key, v])
    end

    if keycode
      return keycode.keyname
    else
      return ''
    end

  end

end
