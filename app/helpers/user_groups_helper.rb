module UserGroupsHelper
  def i18n_restrict_checkout_in_penalty(type)
    case type
    when 0
      t('activerecord.attributes.user_group.restrict_checkout_in_penalty_types.no0')
    when 1
      t('activerecord.attributes.user_group.restrict_checkout_in_penalty_types.yes1')
    when 2
      t('activerecord.attributes.user_group.restrict_checkout_in_penalty_types.yes2')
    else
      t('activerecord.attributes.agent.no_key') 
    end
  end

  def i18n_restrict_checkout_after_penalty(type)
    case type
    when 0
      t('activerecord.attributes.user_group.restrict_checkout_after_penalty_types.no0')
    when 1
      t('activerecord.attributes.user_group.restrict_checkout_after_penalty_types.yes1')
    else
      t('activerecord.attributes.agent.no_key') 
    end
  end
end
