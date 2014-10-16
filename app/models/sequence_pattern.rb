class SequencePattern < ActiveRecord::Base
  has_many :series_statements

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :volume_param ,allow_nil: true, only_integer: true, greater_than: 0
  validates_numericality_of :issue_param ,allow_nil: true, only_integer: true, greater_than: 0
  validates_numericality_of :issue_sequence_param ,allow_nil: true, only_integer: true, greater_than: 0

  paginates_per 20

  def get_next_number(current_volume, current_issue)
    next_volume = self.volume_param.nil? ? nil : current_volume
    next_issue = self.issue_param.nil? ? nil : current_issue

    next_issue = current_issue + self.issue_param if current_issue && self.issue_param
    case Keycode.find(issue_sequence_type).try(:v).to_i
    when 3 then next_issue += 1 if next_issue.to_i.even?
    when 4 then next_issue += 1 if next_issue.to_i.odd?
    end
    if next_issue.present?
      if self.issue_sequence_param
        if next_issue > self.issue_sequence_param 
          if reset_issue_param
            next_issue = 1 if self.issue_param
            next_issue = 2 if Keycode.find(issue_sequence_type).try(:v).to_i == 4
            next_volume = current_volume + self.volume_param if current_volume && self.volume_param
          else
            vol = next_issue.to_f / self.issue_sequence_param.to_f
            next_volume = current_volume + self.volume_param if self.volume_param && (vol > current_volume)
          end
        end
      end
    else
      next_volume = current_volume + self.volume_param if current_volume && self.volume_param
    end

    return [set_format(next_volume, self.volume_sequence_type), set_format(next_issue, self.issue_sequence_type)]
  end

  def set_format(param, sequence_type)
    if param && sequence_type
      param = param.to_i
      case  Keycode.find(sequence_type).try(:v).to_i
      when 0
      when 1 then param = param.ordinalize
      when 2, 3, 4 then param = Date::ABBR_MONTHNAMES[param]
      end
    end
    return param
  end

  def destroy?
    return false if SeriesStatement.where(:sequence_pattern_id => self.id).first
    return true
  end 
end
