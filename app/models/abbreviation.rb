class Abbreviation < ActiveRecord::Base
  attr_accessible :keyword, :v

  # キーワードの検証
  validate :val_keyword
  # 既に登録されているキーワードは登録不可
  validates_uniqueness_of :keyword

  # 略語の検証
  validate :val_v

  def val_keyword
    # 先頭に数字が混ざる可能性があるため、検証する開始文字位置を定める
    string_location = 0
    keyword.split("").each do |spelling|
      if string_location == 0 then
        string_location += 1
      elsif check_first_numeric?(keyword) and
            check_first_numeric?(spelling) then
        string_location += 1
      else
        break
      end
      # すべて数字の場合、検証する開始文字位置を先頭にする
      if string_location >= keyword.length then
        string_location = 0
      end
    end

    errors.add(:keyword) unless
    (check_first_big?(keyword) or
     check_first_numeric?(keyword)) and
    not check_middle_big?(keyword) and
    check_hankaku?(keyword[string_location..keyword.length]) and
    not exists_space?(keyword)
  end

  def val_v
    # 先頭に数字が混ざる可能性があるため、検証する開始文字位置を定める
    string_location = 0
    v.split("").each do |spelling|
      if string_location == 0 then
        string_location += 1
      elsif check_first_numeric?(v) and
            check_first_numeric?(spelling) then
        string_location += 1
      else
        break
      end
      # すべて数字の場合、検証する開始文字位置を先頭にする
      if string_location >= v.length then
        string_location = 0
      end
    end

    errors.add(:v) unless
    (check_first_big?(v) or
     check_first_numeric?(v)) and
    ((v.length == 1) or
     (string_location == 0) or
     (not check_middle_big?(v) and
      check_hankaku?(v[string_location..v.length]) and
      not exists_space?(v)))
  end

  def self.get_abbreviation(bookname)
    # 当モデルのチェックメソッドを使用するため、レシーバのインスタンスを生成する
    abbreviation_res = Abbreviation.new

    merge_v = ""
    bookname.split(" ").each do |key|
      merge_before_v = ""
      # 先頭が大文字または数字の場合
      if abbreviation_res.check_first_big?(key) or
         abbreviation_res.check_first_numeric?(key) then
        abbreviation = Abbreviation.where(keyword: key)
        if not abbreviation.empty?
          merge_before_v = abbreviation[0]['v']
        else
          merge_before_v = key
        end
      # 先頭が半角小文字で、先頭以外に大文字または記号がある場合
      elsif abbreviation_res.check_hankaku_small_string?(key[0]) and
        (abbreviation_res.check_middle_big?(key) or 
         abbreviation_res.check_middle_mark?(key)) then
        merge_before_v = key
      # 上記以外の場合、次の要素へ進む
      else
        next
      end

      if merge_v == "" then
        merge_v = merge_before_v
      else
        merge_v.concat(" ").concat(merge_before_v)
      end
    end
    return merge_v
  end

  # 先頭が大文字かどうか
  def check_first_big?(str)
    if /^[ABCDEFGHIJKLMNOPQRSTUVWXYZ]/ =~ str then
      return true
    else
      return false
    end
  end

  # 先頭が数字かどうか
  def check_first_numeric?(str)
    if /^[0123456789]+/ =~ str then
      return true
    else
      return false
    end
  end

  # 先頭以外に大文字があるかどうか
  def check_middle_big?(str)
    if /.[ABCDEFGHIJKLMNOPQRSTUVWXYZ]+/ =~ str then
      return true
    else
      return false
    end
  end

  # 先頭以外に記号があるかどうか
  def check_middle_mark?(str)
    if /.[!-\/:-@\[-`{-~]+/ =~ str then
      return true
    else
      return false
    end
  end

  # 半角小文字の文字列かどうか
  def check_hankaku_small_string?(str)
    if /[abcdefghijklmnopqrstuvwxyz]/ =~ str then
      return true
    else
      return false
    end
  end

  # 空白があるかどうか
  def exists_space?(str)
    if / / =~ str then
      return true
    else
      return false
    end
  end

  # 半角文字かどうか
  def check_hankaku?(str)
    str.split("").each do |spelling|
      # 半角小文字か
      if check_hankaku_small_string?(spelling) then
        next
      # 半角数字か
      elsif check_first_numeric?(spelling) then
        next
      # 半角記号か
      elsif check_middle_mark?(" #{spelling}") then
        next
      # 上記に該当しない場合、半角文字でないとみなす
      else
        return false
      end
    end
    # 全文字が else とならずに通過した場合、半角文字であるとみなす
    return true
  end
end

