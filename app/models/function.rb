class Function < ActiveRecord::Base
  attr_accessible :controller_name, :display_name, :action_names, :position
  has_many :function_class_abilities, :dependent => :destroy

  validates :display_name, presence: true
  validates :action_names, presence: true
  validates :position, presence: true
  validate :valid_controller_name
  validate :valid_action_names

  def action_spec
    parse_action_names(action_names)
  end

  private

    def valid_controller_name
      unless /\A\w+Controller\z/ =~ controller_name
        self.errors.add(:controller_name, :invalid)
        return
      end

      begin
        controller_name.constantize
      rescue NameError
        self.errors.add(:controller_name, :invalid)
        return
      end
    end

    def valid_action_names
      begin
        parse_action_names(action_names)
      rescue ArgumentError
        errors.add(:action_names, :invalid)
      end
    end

    # 各行の書式が "タイプ:アクション名,...\n" であり
    # タイプが "read"、"update"、"delete" の
    # 三種三行からなるテキストをを解析しハッシュで返す。
    #
    # アクション名のリストはカンマ区切りとし、
    # アクション名は英数字および "_" で構成され
    # 先頭文字が数字以外とする。
    #
    # 以下に例を示す。
    #
    #     read:index,show
    #     update:new,create,edit,update
    #     delete:destroy
    #
    # 最終行を含め、行末に改行文字を必須とする。
    ACTION_TYPES = [:read, :update, :delete]
    ACTION_NAME_PATTERN = /[a-zA-Z]\w*/
    ACTION_TYPE_PATTERN = /#{ACTION_TYPES.map {|s| Regexp.quote(s.to_s)}.join('|')}/
    ACTION_LINE_PATTERN = /^(#{ACTION_TYPE_PATTERN}):((?:#{ACTION_NAME_PATTERN}(?:,#{ACTION_NAME_PATTERN})*)?)\n/
    def parse_action_names(text)
      if text.blank?
        raise ArgumentError, "empty action names"
      end

      result = {}

      text.each_line do |line|
        unless ACTION_LINE_PATTERN =~ line
          raise ArgumentError, "invalid action line: #{line}"
        end
        if result.include?($1)
          raise ArgumentError, "duplicated action type: #{$1}"
        end
        result[$1.to_sym] = $2.split(/,/)
      end

      unless result.keys.sort == ACTION_TYPES.sort
        raise ArgumentError, "incomplete action types"
      end

      result
    end
end
