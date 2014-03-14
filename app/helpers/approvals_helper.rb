module ApprovalsHelper

  def select_publication_status

    if respond_to? :publication_status_key
      return Keycode.find(:all, :conditions => ["name = ?",publication_status_key])
    end
  end


  def select_sample_carrier_type

    if respond_to? :sample_carrier_types_key
      return Keycode.find(:all, :conditions => ["name = ?",sample_carrier_types_key])
    end
  end

  def select_group_approval_result

    if respond_to? :group_approval_result_types_key
      return Keycode.find(:all, :conditions => ["name = ?",group_approval_result_types_key])
    end
  end

  def select_group_result_reason

    if respond_to? :group_result_reason_key
      return Keycode.find(:all, :conditions => ["name = ?",group_result_reason_key])
    end
  end

  def select_approval_result

    if respond_to? :approval_result_key
      return Keycode.find(:all, :conditions => ["name = ?",approval_result_key])
    end
  end

  def select_reason
    if respond_to? :approval_reason_key
      return Keycode.find(:all, :conditions => ["name = ?",approval_reason_key])
    end
  end

  def select_donate_request_result
    if respond_to? :donate_request_result_key
      return Keycode.find(:all, :conditions => ["name = ?",donate_request_result_key])
    end
  end

  def select_thrsis_review_flg
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", thrsis_review_flg_key, Time.zone.now) rescue nil
  end

  def select_ja_text_author_summary_flg
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", ja_text_author_summary_flg_key, Time.zone.now) rescue nil
  end

  def select_en_text_author_summary_flg
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", en_text_author_summary_flg_key, Time.zone.now) rescue nil
  end

  def select_four_priority_areas
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", four_priority_areas_key, Time.zone.now) rescue nil
  end

  def select_document_classification_1
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", document_classification_1_key, Time.zone.now) rescue nil
  end

  def select_document_classification_2
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", document_classification_2_key, Time.zone.now) rescue nil
  end

  def get_keyname_publication_status(v)
    if respond_to? :publication_status_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", publication_status_key, v])
    end

    if keycode
      return keycode.keyname
    else
      return ''
    end
  end


  def get_keyname_sample_carrier_type(v)

    if respond_to? :sample_carrier_types_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", sample_carrier_types_key, v])
    end
    if keycode
      return keycode.keyname
    else
      return ''
    end
  end

  def get_keyname_group_approval_result(v)

    if respond_to? :group_approval_result_types_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", group_approval_result_types_key, v])
    end
    if keycode
      return keycode.keyname
    else
      return ''
    end
  end

  def get_keyname_group_result_reason(v)

    if respond_to? :group_result_reason_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", group_result_reason_key, v])
    end
    if keycode
      return keycode.keyname
    else
      return ''
    end

  end

  def get_keyname_approval_result(v)

    if respond_to?  :approval_result_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", approval_result_key, v])
    end
    if keycode
      return keycode.keyname
    else
      return ''
    end
  end


  def get_keyname_reason(v)

    if respond_to? :approval_reason_key
      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", approval_reason_key, v])
    end

    if keycode
      return keycode.keyname
    else
      return ''
    end
  end

  def get_keyname_donate_request_result(v)

    if respond_to? :donate_request_result_key

      keycode = Keycode.find(:first, :conditions => ["name = ? and v = ?", donate_request_result_key, v])
    end

    if keycode
      return keycode.keyname
    else
      return ''
    end

  end


end

