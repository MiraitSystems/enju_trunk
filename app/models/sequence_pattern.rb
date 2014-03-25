class SequencePattern < ActiveRecord::Base
  has_many :series_statements

  SEQUENCE_TYPE = { 0 => 'cardinal', 1 => 'ordinal', 2 => 'month'}

  def get_next_number(current_volume, current_issue)
    next_volume, next_issue = nil, nil
    next_issue = current_issue + self.issue_param if current_issue && self.issue_param
    unless next_issue.nil?
      if self.volume_param && next_issue > self.volume_param * self.issue_param
        next_issue = 1 if self.issue_param
        next_volume = current_volume + 1 if current_volume && self.volume_param
      else
        next_volume = current_volume
      end

      case self.sequence_type
      when 0 # cardinal
      when 1 # ordinal
        next_issue = next_issue.ordinalize 
      when 2 # month
        next_issue = Date::ABBR_MONTHNAMES[next_issue]
      end
    end
    return [next_volume, next_issue]
  end

  def self.sequence_types
    SEQUENCE_TYPE
  end

  def destroy?
    return false if SeriesStatement.where(:sequence_pattern_id => self.id).first
    return true
  end 
end
