class FunctionClassAbility < ActiveRecord::Base
  attr_accessible :ability, :function_class, :function_class_id, :function, :function_id
  belongs_to :function
  belongs_to :function_class

  class_attribute :labels
  self.labels = {
    none: 0,
    read: 1,
    update: 2,
    delete: 3,
  }

  validates :function, associated: :function, presence: true
  validates :function_class, associated: :function_class, presence: true
  validates :ability, presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0}

  # 指定されたコントローラのアクションを
  # 実行するために必要な権限を抽出する
  def self.required_ability(controller_class, action_name)
    abilities = []

    Function.where(controller_name: controller_class.name).map do |function|
      function.action_spec.each do |type, anames|
        next unless anames.include?(action_name)
        abilities << labels[type]
      end
    end

    abilities.min
  end

  # コントローラのアクションを
  # ユーザが実行できるかどうかを検査する
  def self.permit?(controller_class, action_name, user)

    # 制限対象となる機能として設定されているか検査する
    function = Function.where(controller_name: controller_class.name).first
    unless function
      # 設定がない(制限対象ではない)ので許可する
      return true
    end

    if user
      # ユーザが属するクラスを抽出する
      user_fclass_id = user.function_class_id
      user_fclass_id ||= FunctionClass.noclass_id # 機能クラス"noclass"があればそれに従う
    else
      # ユーザが未定義(未ログイン状態)の場合
      # 機能クラス"nobody"があればそれに従う
      user_fclass_id = FunctionClass.nobody_id

      # nobodyの設定がなければ
      # 利用者が持つべき権限が不明のため、安全のため拒絶する
      return false unless user_fclass_id
    end

    # 実行するアクションに必要な権限を抽出する
    required_ability = required_ability(controller_class, action_name)
    unless required_ability
      # アクションに対して必要とされる権限が設定されていない(不明なアクションである)ため、安全のため拒絶する
      return false
    end

    # 必要な権限を満たすレコードを検索する
    where(function_id: function.id).
      where(function_class_id: user_fclass_id).
      where(['ability >= ?', required_ability]).
      count > 0 # 見付かれば許可、そうでなければ拒否
  end
end
