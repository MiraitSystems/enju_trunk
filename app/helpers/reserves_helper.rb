module ReservesHelper
  def i18n_state(state)
    case state
    when 'pending'
      t('reserve.pending')
    when 'requested'
      t('reserve.requested')
    when 'retained'
      t('reserve.retained')
    when 'canceled'
      t('reserve.canceled')
    when 'expired'
      t('reserve.expired')
    when 'completed'
      t('reserve.completed')
    end
  end

  def i18n_information_type(id)
    case id
      when 0
        t('activerecord.attributes.reserve.email')
      when 1
        t('activerecord.attributes.reserve.telephone')
      when 2
        t('activerecord.attributes.reserve.unnecessary')
    end
  end
  
  def button_to_by_get(name, options = {}, html_options = {}, parameter = {})
    html_options.merge!({:method => :get})

    result = button_to(name, options, html_options)
    return result if parameter.empty?

    parameter_tag = ''
    parameter.each_pair do |key, value|
      parameter_tag += tag('input',
        :type => 'hidden', :name => key.to_s, :value => value.to_s)
    end
    result.sub(/(><div>)/, '\1' + parameter_tag).html_safe
  end

  def move_position_for_reserve(object, option = {})
    render :partial => 'position', :locals => {:object => object, :option => option}
  end
end
