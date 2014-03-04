module ItemsHelper
  def call_numberformat(item = nil)
    call_number = item.call_number
    if SystemConfiguration.get("items.call_number.delete_first_delimiter")
      delimiter = item.try(:shelf).try(:library).try(:call_number_delimiter) || '|'
      if call_number
        if call_number.slice(0, 1) == delimiter
          call_number.slice!(0, 1)
        end
      end
    end
    results = call_number.gsub(/\s/, delimiter) rescue nil
    return results
  end

  def item_ranks
    return [0, 1, 2]
  end

  def i18n_rank(item)
    case item
    when 0
      t('item.original')
    when 1
      t('item.copy')
    when 2
      t('item.spare')
    end
  end

  def circulation_statuses
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", circulation_status_key, Time.zone.now) rescue nil
  end

  def shelfs
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", shelf_key, Time.zone.now) rescue nil
  end

  def get_circulation_status(v)
    if respond_to? :circulation_status_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", circulation_status_key, v])
    end
    if keycode
      return keycode.keyname
    else
      return ''
    end
  end

end
