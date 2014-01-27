module UseLicensesHelper
  def targets
    return Keycode.where("name = ? AND (ended_at > ? OR ended_at IS NULL)", use_licenses_targets_key, Time.zone.now) rescue nil
  end

  def authors
    return Keycode.where("name = ? AND (ended_at > ? OR ended_at IS NULL)", use_licenses_authors_key, Time.zone.now) rescue nil
  end
end
