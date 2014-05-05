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

  # コントローラのアクションを
  # ユーザが実行できるかどうかを検査する
  def self.permit?(controller_class, action_name, user)
    # 制限対象となる機能として設定されているか検査する
    unless Function.where(controller_name: controller_class.name).exists?
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

    # 対象となるコントローラ・アクションの権限レコードを検索する
    fability = joins(:function).
      where(functions: {controller_name: controller_class.name}).
      where(function_class_id: user_fclass_id).all
    return false if fability.blank?

    fability.any? do |fa|
      fa.include_action?(action_name)
    end
  end

  # 権限のabilityの範囲で
  # 指定されたアクションが
  # 許可されているかどうかを返す
  def include_action?(action_name)
    function.action_spec.any? do |type, anames|
      self.class.labels[type] <= ability &&
        anames.include?(action_name)
    end
  end
end
