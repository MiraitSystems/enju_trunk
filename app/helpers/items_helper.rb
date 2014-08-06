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
    rank = Struct.new(:id, :text)
    ranks = []
    ranks << rank.new(0, i18n_rank(0))
    ranks << rank.new(1, i18n_rank(1))
    ranks << rank.new(2, i18n_rank(2))
    return ranks
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

  def budget_category_group(id)
    return Keycode.find(id).keyname
  end 
end
