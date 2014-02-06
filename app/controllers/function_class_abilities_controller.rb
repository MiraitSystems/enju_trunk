class FunctionClassAbilitiesController < InheritedResources::Base
  add_breadcrumb "I18n.t('activerecord.models.function_class_ability')", 'function_class_function_class_abilities_path(params[:function_class_id])'
  belongs_to :function_class

  # POST /function_class/:function_class_id/function_class_abilities
  #
  # 'function_class_abilities' => {function_id => ability, ...}を受けて
  # function_class_id、function_idの組み合わせに対するabilityを設定する。
  # (設定がなければ新たに作成する。)
  def update_all
    changed = failed = 0
    abilities = {}

    (params['function_class_abilities'] || {}).each do |function_id, ability|
      next unless /\A\d+\z/ =~ function_id
      next unless /\A\d+\z/ =~ ability
      abilities[function_id.to_i] = ability.to_i
    end

    if abilities.present?
      functions = Function.find(abilities.keys).inject({}) {|h, f| h[f.id] = f; h }

      FunctionClassAbility.
        where(function_class_id: parent.id).
        where(function_id: functions.keys).
        each do |fc_ability|
          function_id = fc_ability.function_id
          fc_ability.ability = abilities[function_id]
          if fc_ability.changed?
            if fc_ability.save
              logger.debug "succeeded to update ability: function=#{function_id},function_class=#{parent.id},ability=#{fc_ability.ability}->#{abilities[function_id]}"
              changed += 1
            else
              logger.info "failed to update ability: function=#{function_id},function_class=#{parent.id},ability=#{fc_ability.ability}->#{abilities[function_id]}"
              failed += 1
            end
          end
          functions.delete(function_id)
        end

      functions.each do |function_id, function|
        fc_ability = FunctionClassAbility.new(
          function_id: function_id,
          function_class_id: parent.id,
          ability: abilities[function_id]
        )
        if fc_ability.save
          logger.debug "succeeded to create ability: function=#{function_id},function_class=#{parent.id},ability=#{abilities[function_id]}"
          changed += 1
        else
          logger.info "failed to create ability: function=#{function_id},function_class=#{parent.id},ability=#{abilities[function_id]}"
          failed += 1
        end
      end
    end

    if changed > 0 && failed > 0
      flash[:notice] = t('function_class_abilities.partially_updated')
    elsif changed > 0
      flash[:notice] = t('function_class_abilities.successfully_updated')
    elsif failed > 0
      flash[:notice] = t('function_class_abilities.update_failed')
    end

    redirect_to(function_class_function_class_abilities_path(
      function_class_id: parent.id))
  end

  protected

    def collection
      return @function_class_abilities if defined?(@function_class_abilities)

      fc_abilities = FunctionClassAbility.
        where(function_class_id: parent).
        includes(:function).
        all.inject({}) do |h, fc|
          h[fc.function_id] = fc
          h
        end

      @function_class_abilities =
        Function.all.map do |function|
          fc_abilities[function.id] ||
            FunctionClassAbility.new(
              function_class: @function_class,
              function: function)
        end
    end
end
